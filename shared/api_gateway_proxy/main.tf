# Required variables:
variable "environment" {
  description = "The environment for this application: development, qa, or production."
}

variable "name" {
  description = "The application name."
}

variable "function" {
  # TODO: This should be a key-value mapping of paths to functions.
  description = "The Lambda function's ARN."
}

data "aws_lambda_function" "function" {
  function_name = "${var.function}"

  # Don't fetch the fully qualified ARN. <https://git.io/fh9WK>
  qualifier = ""
}

resource "aws_api_gateway_rest_api" "gateway" {
  name        = "${var.name}"
  description = "Managed with Terraform."
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.gateway.id}"
  parent_id   = "${aws_api_gateway_rest_api.gateway.root_resource_id}"
  path_part   = "{proxy+}"
}

# We need separate proxies for the "root" path '/' and everything else '/*'
# because reasons. Frustrating, but luckily we can abstract this away.
resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.gateway.id}"
  resource_id   = "${aws_api_gateway_rest_api.gateway.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.gateway.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"

  # Lambda functions can only be invoked via POST.
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${data.aws_lambda_function.function.invoke_arn}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = "${aws_api_gateway_rest_api.gateway.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.gateway.id}"
  resource_id = "${aws_api_gateway_method.proxy.resource_id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"

  # Lambda functions can only be invoked via POST.
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${data.aws_lambda_function.function.invoke_arn}"
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    "aws_api_gateway_integration.lambda",
    "aws_api_gateway_integration.lambda_root",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.gateway.id}"
  stage_name  = "${var.environment}"
}

resource "aws_lambda_permission" "gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${var.function}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any HTTP method on any resource.
  source_arn = "${aws_api_gateway_deployment.deployment.execution_arn}/*/*"
}

output "base_url" {
  value = "${aws_api_gateway_deployment.deployment.invoke_url}"
}

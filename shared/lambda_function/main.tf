# Experimental: This module builds a serverless Lambda function.

# Required variables:
variable "environment" {
  description = "The environment for this application: development, qa, or production."
}

variable "name" {
  description = "The application name."
}

# Optional variables:
variable "config_vars" {
  description = "Environment variables for this application."
  default     = {}
}

locals {
  safe_name = "${replace(var.name, "-", "_")}"
}

# The lambda function and API gateway:
resource "aws_lambda_function" "function" {
  function_name = "${var.name}"
  handler       = "main.handler"

  s3_bucket = "${aws_s3_bucket.deploy.id}"
  s3_key    = "${aws_s3_bucket_object.build.key}"

  runtime = "nodejs8.10"

  environment {
    variables = "${var.config_vars}"
  }

  role = "${aws_iam_role.lambda_exec.arn}"
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
  uri                     = "${aws_lambda_function.function.invoke_arn}"
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
  uri                     = "${aws_lambda_function.function.invoke_arn}"
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
  function_name = "${aws_lambda_function.function.arn}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any HTTP method on any resource.
  source_arn = "${aws_api_gateway_deployment.deployment.execution_arn}/*/*"
}

# Deploy artifacts:
resource "aws_s3_bucket" "deploy" {
  bucket = "${var.name}-deploy"
  acl    = "private"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_object" "build" {
  bucket = "${aws_s3_bucket.deploy.id}"
  key    = "${local.safe_name}.zip"
  source = "${path.module}/example.zip"
}

# Log group:
resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/${aws_lambda_function.function.function_name}"
  retention_in_days = 14

  # TODO: How can we hook this up to our Papertrail forwarder?
}

# This is the "execution" role that is used to run this function:
resource "aws_iam_role" "lambda_exec" {
  name = "${var.name}"

  assume_role_policy = "${file("${path.module}/exec-policy.json")}"
}

resource "aws_iam_policy" "lambda_logging" {
  name = "${var.name}-logging"
  path = "/"

  policy = "${file("${path.module}/logging-policy.json")}"
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = "${aws_iam_role.lambda_exec.name}"
  policy_arn = "${aws_iam_policy.lambda_logging.arn}"
}

# This is the "deploy" role that is used to deploy new code:
resource "aws_iam_user" "lambda_deploy" {
  name = "${var.name}-deploy"
}

resource "aws_iam_user_policy" "deploy_policy" {
  user   = "${aws_iam_user.lambda_deploy.name}"
  policy = "${data.template_file.deploy_policy.rendered}"
}

data "template_file" "deploy_policy" {
  template = "${file("${path.module}/deploy-policy.json.tpl")}"

  vars {
    deploy_bucket_arn   = "${aws_s3_bucket.deploy.arn}"
    lambda_function_arn = "${aws_lambda_function.function.arn}"
  }
}

resource "aws_iam_access_key" "deploy_key" {
  user = "${aws_iam_user.lambda_deploy.name}"
}

output "lambda_role" {
  value = "${aws_iam_role.lambda_exec.name}"
}

output "backend" {
  value = "${aws_api_gateway_deployment.deployment.invoke_url}"
}

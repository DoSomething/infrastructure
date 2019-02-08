locals {
  # Hack! Check if `var.domain` is a DS.org subdomain. <https://stackoverflow.com/a/47243622/811624>
  is_dosomething_domain = "${replace(var.domain, ".dosomething.org", "") != var.domain}"
}

resource "aws_api_gateway_rest_api" "gateway" {
  name        = "${var.name}"
  description = "Managed with Terraform."
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
  uri                     = "${var.function_invoke_arn}"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.gateway.id}"
  parent_id   = "${aws_api_gateway_rest_api.gateway.root_resource_id}"
  path_part   = "{proxy+}"
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
  uri                     = "${var.function_invoke_arn}"
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
  function_name = "${var.function_arn}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any HTTP method on any resource.
  source_arn = "${aws_api_gateway_deployment.deployment.execution_arn}/*/*"
}

# Custom domain (optional):
data "aws_acm_certificate" "certificate" {
  count = "${var.domain == "" ? 0 : 1}"

  # If this is a *.dosomething.org subdomain, use our wildcard ACM certificate.
  # Otherwise, find a certificate for the provided domain (manually provisioned).
  domain = "${local.is_dosomething_domain ? "*.dosomething.org" : var.domain}"

  statuses = ["ISSUED"]
}

resource "aws_api_gateway_domain_name" "domain" {
  count = "${var.domain == "" ? 0 : 1}"

  certificate_arn = "${data.aws_acm_certificate.certificate.arn}"
  domain_name     = "${var.domain}"
}

resource "aws_api_gateway_base_path_mapping" "mapping" {
  count = "${var.domain == "" ? 0 : 1}"

  api_id      = "${aws_api_gateway_rest_api.gateway.id}"
  stage_name  = "${aws_api_gateway_deployment.deployment.stage_name}"
  domain_name = "${aws_api_gateway_domain_name.domain.domain_name}"
}

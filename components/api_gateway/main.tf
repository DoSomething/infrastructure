locals {
  # Hack! Check if `var.domain` is a DS.org subdomain. <https://stackoverflow.com/a/47243622/811624>
  is_dosomething_domain = "${replace(var.domain, ".dosomething.org", "") != var.domain}"
}

resource "aws_api_gateway_rest_api" "gateway" {
  name        = "${var.name}"
  description = "Managed with Terraform."
}

# Configure the root resource method & integration:
resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.gateway.id}"
  resource_id   = "${aws_api_gateway_rest_api.gateway.root_resource_id}"
  http_method   = "${var.root_method}"
  authorization = "${var.root_authorization}"
  authorizer_id = "${var.root_authorizer_id}"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.gateway.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"

  # Lambda functions can only be invoked via POST.
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${var.root_function}"
}

# Configure any other routes, specified in the `routes` variable.
resource "aws_api_gateway_resource" "resource" {
  count = "${length(var.routes)}"

  rest_api_id = "${aws_api_gateway_rest_api.gateway.id}"
  parent_id   = "${aws_api_gateway_rest_api.gateway.root_resource_id}"
  path_part   = "${lookup(var.routes[count.index], "path")}"
}

resource "aws_api_gateway_method" "method" {
  count = "${length(var.routes)}"

  rest_api_id   = "${aws_api_gateway_rest_api.gateway.id}"
  resource_id   = "${aws_api_gateway_resource.resource.*.id[count.index]}"
  http_method   = "${lookup(var.routes[count.index], "method", "ANY")}"
  authorization = "${lookup(var.routes[count.index], "authorization", "NONE")}"
  authorizer_id = "${lookup(var.routes[count.index], "authorizer_id", "")}"
}

resource "aws_api_gateway_integration" "integration" {
  count = "${length(var.routes)}"

  rest_api_id = "${aws_api_gateway_rest_api.gateway.id}"
  resource_id = "${aws_api_gateway_method.method.*.resource_id[count.index]}"
  http_method = "${aws_api_gateway_method.method.*.http_method[count.index]}"

  # Lambda functions can only be invoked via POST.
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${lookup(var.routes[count.index], "function")}"
}

resource "aws_api_gateway_deployment" "deployment" {
  # Since this resource implicitly depends on all of the routes
  # being configured, we'll set a explicit dependency here.
  depends_on = [
    "aws_api_gateway_integration.lambda_root",
    "aws_api_gateway_integration.integration",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.gateway.id}"
  stage_name  = "default"
}

resource "aws_lambda_permission" "gateway_permission" {
  count = "${length(var.functions)}"

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${var.functions[count.index]}"
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

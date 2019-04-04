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

# Verify that the count matches the list <https://git.io/fjLYC>
resource "null_resource" "verify_routes_count" {
  provisioner "local-exec" {
    command = <<SH
if [ ${var.routes_count} -ne ${length(var.routes)} ]; then
echo "var.routes_count must match the actual length of var.routes";
exit 1;
fi
SH
  }

  # Re-run this check if the inputted variables change:
  triggers {
    routes_count_computed = "${length(var.routes)}"
    routes_count_provided = "${var.routes_count}"
  }
}

# Configure any other routes, specified in the `routes` variable.
resource "aws_api_gateway_resource" "resource" {
  count = "${var.routes_count}"

  rest_api_id = "${aws_api_gateway_rest_api.gateway.id}"
  parent_id   = "${aws_api_gateway_rest_api.gateway.root_resource_id}"
  path_part   = "${lookup(var.routes[count.index], "path")}"
}

resource "aws_api_gateway_method" "method" {
  count = "${var.routes_count}"

  rest_api_id   = "${aws_api_gateway_rest_api.gateway.id}"
  resource_id   = "${aws_api_gateway_resource.resource.*.id[count.index]}"
  http_method   = "${lookup(var.routes[count.index], "method", "ANY")}"
  authorization = "${lookup(var.routes[count.index], "authorization", "NONE")}"
  authorizer_id = "${lookup(var.routes[count.index], "authorizer_id", "")}"
}

resource "aws_api_gateway_integration" "integration" {
  count = "${var.routes_count}"

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

  # HACK: We need to re-trigger a deployment if the routes for this API Gateway
  # change. We can do so by modifying the stage description. <https://git.io/fjLs3>
  # stage_description = "Hash: ${md5(jsonencode(var.routes))}"
}

# Verify that the count matches the list <https://git.io/fjLYC>
resource "null_resource" "verify_functions_count" {
  provisioner "local-exec" {
    command = <<SH
if [ ${var.functions_count} -ne ${length(var.functions)} ]; then
echo "var.functions_count must match the actual length of var.functions";
exit 1;
fi
SH
  }

  # Re-run this check if the inputted variables change:
  triggers {
    functions_count_computed = "${length(var.functions)}"
    functions_count_provided = "${var.functions_count}"
  }
}

resource "aws_lambda_permission" "gateway_permission" {
  count = "${var.functions_count}"

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

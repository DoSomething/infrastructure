module "api_gateway" {
  source = "../api_gateway"

  name      = "${var.name}"
  functions = ["${var.function_arn}"]
  domain    = "${var.domain}"

  root_function = "${var.function_invoke_arn}"

  routes = [
    {
      path     = "{proxy+}"
      function = "${var.function_invoke_arn}"
    },
  ]
}

module "api_gateway" {
  source = "../api_gateway"

  name        = var.name
  environment = var.environment
  stack       = var.stack

  domain      = var.domain
  certificate = var.certificate

  functions_count = 1
  functions       = [var.function_arn]

  root_function = var.function_invoke_arn

  routes_count = 1

  routes = [
    {
      path     = "{proxy+}"
      function = var.function_invoke_arn
    },
  ]
}


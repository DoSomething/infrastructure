module "api_gateway" {
  source = "../api_gateway"

  name   = var.name
  domain = var.domain

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


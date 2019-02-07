variable "logger" {
  description = "The Lambda function ARN to subscribe to this function's log group."
  default     = ""
}

module "app" {
  source = "../../shared/lambda_function"

  name   = "hello-serverless"
  logger = "${var.logger}"
}

module "gateway" {
  source = "../../shared/api_gateway_proxy"

  name                = "hello-serverless"
  function_arn        = "${module.app.arn}"
  function_invoke_arn = "${module.app.invoke_arn}"
}

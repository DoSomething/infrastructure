variable "logger" {
  description = "The Lambda function ARN to subscribe to this function's log group."
}

module "app" {
  source = "../../components/lambda_function"

  name    = "hello-serverless"
  runtime = "nodejs8.10"
  logger  = "${var.logger}"
}

module "gateway" {
  source = "../../components/api_gateway_proxy"

  name                = "hello-serverless"
  environment         = "development"
  function_arn        = "${module.app.arn}"
  function_invoke_arn = "${module.app.invoke_arn}"
  domain              = "hello-serverless.dosomething.org"
}

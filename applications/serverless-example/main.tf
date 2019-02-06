module "app" {
  source = "../../shared/lambda_function"

  name = "hello-serverless"
}

module "gateway" {
  source = "../../shared/api_gateway_proxy"

  name                = "hello-serverless"
  environment         = "development"
  function_arn        = "${module.app.arn}"
  function_invoke_arn = "${module.app.invoke_arn}"
  domain              = "hello-serverless.dosomething.org"
}

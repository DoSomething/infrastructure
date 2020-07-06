# Experimental: This module builds a serverless GraphQL instance.

# Required variables:
variable "environment" {
  description = "The environment for this application: development, qa, or production."
}

variable "name" {
  description = "The application name."
}

variable "northstar_url" {
  description = "The corresponding Northstar URL."
}

# Optional variables:
variable "domain" {
  description = "The domain this application will be accessible at, e.g. dev.dosome.click"
  default     = ""
}

variable "certificate" {
  description = "The ACM certificate to use for this domain, e.g. *.dosomething.org"
  default     = ""
}

variable "logger" {
  description = "The Lambda function ARN to subscribe to this function's log group."
  default     = null
}

data "aws_ssm_parameter" "bertly_api_key" {
  name = "/${var.name}/api-key"
}

locals {
  # This application is part of our backend stack.
  stack = "backend"

  config_vars = {
    APP_NAME   = var.name
    APP_URL    = "https://${var.domain}"
    APP_SECRET = random_string.app_secret.result
    NODE_ENV   = "production"
    LOG_LEVEL  = "info"
    PORT       = 80

    OPENID_DISCOVERY_URL = var.northstar_url
    BERTLY_API_KEY_NAME  = "X-BERTLY-API-KEY"
    BERTLY_API_KEY       = data.aws_ssm_parameter.bertly_api_key.value
  }
}

module "app" {
  source = "../../components/lambda_function"

  application = var.name
  name        = var.name
  environment = var.environment
  stack       = local.stack

  handler = "bootstrap/lambda.handler"
  runtime = "nodejs12.x"
  logger  = var.logger

  config_vars = merge(local.config_vars, module.storage.config_vars)
}

resource "random_string" "app_secret" {
  length = 32
}

module "gateway" {
  source = "../../components/api_gateway_proxy"

  name        = var.name
  environment = var.environment
  stack       = local.stack

  function_arn        = module.app.arn
  function_invoke_arn = module.app.invoke_arn

  domain      = var.domain
  certificate = var.certificate
}

module "database" {
  source = "../../components/dynamodb_policy"

  name  = var.name
  roles = [module.app.lambda_role]
}

module "storage" {
  source = "../../components/s3_bucket"

  application = var.name
  name        = "${var.name}-logs"
  environment = var.environment
  stack       = local.stack

  roles   = [module.app.lambda_role]
  private = true
}

module "fivetran_role" {
  source = "../../components/fivetran_s3_role"

  environment = var.environment
  name        = var.name
  bucket      = module.storage.bucket
}

output "backend" {
  value = module.gateway.base_url
}


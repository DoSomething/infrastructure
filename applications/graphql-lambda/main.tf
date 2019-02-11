# Experimental: This module builds a serverless GraphQL instance.

# Required variables:
variable "environment" {
  description = "The environment for this application: development, qa, or production."
}

variable "name" {
  description = "The application name."
}

# Optional variables:
variable "domain" {
  description = "The domain this application will be accessible at, e.g. graphql-lambda.dosomething.org"
  default     = ""
}

variable "logger" {
  description = "The Lambda function ARN to subscribe to this function's log group."
  default     = ""
}

data "aws_ssm_parameter" "contentful_gambit_space_id" {
  # All environments of this application use the same space.
  name = "/contentful/gambit/space-id"
}

data "aws_ssm_parameter" "contentful_api_key" {
  name = "/${var.name}/contentful/gambit/content-api-key"
}

data "aws_ssm_parameter" "gambit_username" {
  name = "/gambit/${local.gambit_env}/username"
}

data "aws_ssm_parameter" "gambit_password" {
  name = "/gambit/${local.gambit_env}/password"
}

data "aws_ssm_parameter" "apollo_engine_api_key" {
  name = "/${var.name}-lambda/apollo/api-key"
}

locals {
  # Environment (e.g. 'dev' or 'DEV')
  env = "${var.environment == "development" ? "dev" : var.environment}"
  ENV = "${upper(local.env)}"

  # Gambit only has a production & QA environment:
  gambit_env = "${local.env == "dev" ? "qa" : local.env}"
}

module "app" {
  source = "../../components/lambda_function"

  name    = "${var.name}"
  runtime = "nodejs8.10"
  logger  = "${var.logger}"

  config_vars = {
    # TODO: Update application to expect 'development' here.
    QUERY_ENV = "${local.env}"

    # Use DynamoDB for caching:
    CACHE_DRIVER   = "dynamodb"
    DYNAMODB_TABLE = "${module.cache.name}"

    # TODO: Remove custom environment mapping once we have a 'dev' instance of Gambit.
    "${upper(local.gambit_env)}_GAMBIT_BASIC_AUTH_USER" = "${data.aws_ssm_parameter.gambit_username.value}"
    "${upper(local.gambit_env)}_GAMBIT_BASIC_AUTH_PASS" = "${data.aws_ssm_parameter.gambit_password.value}"

    # TODO: Remove Gambit Conversations vars once https://github.com/DoSomething/graphql/pull/57 is deployed everywhere.
    "${upper(local.gambit_env)}_GAMBIT_CONVERSATIONS_USER" = "${data.aws_ssm_parameter.gambit_username.value}"
    "${upper(local.gambit_env)}_GAMBIT_CONVERSATIONS_PASS" = "${data.aws_ssm_parameter.gambit_password.value}"

    GAMBIT_CONTENTFUL_SPACE_ID     = "${data.aws_ssm_parameter.contentful_gambit_space_id.value}"
    GAMBIT_CONTENTFUL_ACCESS_TOKEN = "${data.aws_ssm_parameter.contentful_api_key.value}"

    ENGINE_API_KEY = "${data.aws_ssm_parameter.apollo_engine_api_key.value}"
  }
}

module "gateway" {
  source = "../../components/api_gateway_proxy"

  name                = "${var.name}"
  function_arn        = "${module.app.arn}"
  function_invoke_arn = "${module.app.invoke_arn}"
  domain              = "${var.domain}"
}

module "cache" {
  source = "../../components/dynamodb_cache"

  name = "${var.name}-cache"
  role = "${module.app.lambda_role}"
}

output "backend" {
  value = "${module.gateway.base_url}"
}

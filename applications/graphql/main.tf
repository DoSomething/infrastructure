# This template builds a GraphQL application instance.
#
# Manual setup steps:
#   - Create an Apollo Engine service for this application, and copy the API key
#     into '/{$var.name}/apollo/api-key' in SSM.
#   - Create a Gambit Contentful API key for this application, and copy the content
#     API key into '/{var.name}/contentful/gambit-content-api-key' in SSM.
#   - Create a web Northstar OAuth client with the following settings and copy the
#     client secret into '/northstar/{var.environment}/clients/{var.name}' in SSM:
#         Redirect URI: http://{var.domain}/auth/callback
#         Allowed Scopes: 'role:admin', 'role:staff', 'user', 'activity', 'write'
#
# NOTE: We'll move more of these steps into Terraform over time!

# Required variables:
variable "environment" {
  description = "The environment for this application: development, qa, or production."
}

variable "pipeline" {
  description = "The Heroku pipeline ID this application should be created in."
}

variable "domain" {
  description = "The domain this application will be accessible at, e.g. graphql.dosomething.org"
}

variable "name" {
  description = "The application name."
}

variable "papertrail_destination" {
  description = "The Papertrail log destination for this application."
}

data "aws_ssm_parameter" "contentful_gambit_space_id" {
  # All environments of this application use the same space.
  name = "/contentful/gambit/space-id"
}

data "aws_ssm_parameter" "contentful_api_key" {
  name = "/${var.name}/contentful/gambit/content-api-key"
}

data "aws_ssm_parameter" "northstar_auth_secret" {
  name = "/northstar/${var.environment}/clients/${var.name}"
}

data "aws_ssm_parameter" "gambit_username" {
  name = "/gambit/${local.gambit_env}/username"
}

data "aws_ssm_parameter" "gambit_password" {
  name = "/gambit/${local.gambit_env}/password"
}

data "aws_ssm_parameter" "apollo_engine_api_key" {
  name = "/${var.name}/apollo/api-key"
}

locals {
  # Environment (e.g. 'dev' or 'DEV')
  env = "${var.environment == "development" ? "dev" : var.environment}"
  ENV = "${upper(local.env)}"

  # Gambit only has a production & QA environment:
  gambit_env = "${local.env == "dev" ? "qa" : local.env}"
}

resource "random_string" "app_secret" {
  length = 32
}

module "app" {
  source = "../../components/heroku_app"

  framework   = "express"
  name        = "${var.name}"
  domain      = "${var.domain}"
  pipeline    = "${var.pipeline}"
  environment = "${var.environment}"

  config_vars = {
    APP_SECRET = "${random_string.app_secret.result}"

    # TODO: Update application to expect 'development' here.
    QUERY_ENV = "${local.env}"

    "${local.ENV}_NORTHSTAR_AUTH_ID"     = "${var.name}"
    "${local.ENV}_NORTHSTAR_AUTH_SECRET" = "${data.aws_ssm_parameter.northstar_auth_secret.value}"

    # TODO: Remove custom environment mapping once we have a 'dev' instance of Gambit Conversations.
    "${upper(local.gambit_env)}_GAMBIT_CONVERSATIONS_USER" = "${data.aws_ssm_parameter.gambit_username.value}"
    "${upper(local.gambit_env)}_GAMBIT_CONVERSATIONS_PASS" = "${data.aws_ssm_parameter.gambit_password.value}"

    # TODO: Remove 'APOLLO_ENGINE_API_KEY' once dosomething/graphql#41 is deployed everywhere.
    APOLLO_ENGINE_API_KEY = "${data.aws_ssm_parameter.apollo_engine_api_key.value}"
    ENGINE_API_KEY        = "${data.aws_ssm_parameter.apollo_engine_api_key.value}"
  }

  # This application doesn't have a queue.
  queue_scale = 0

  with_redis = true
  redis_type = "${var.environment == "production" ? "premium-1" : "hobby-dev"}"

  papertrail_destination = "${var.papertrail_destination}"
  with_newrelic          = false
}

output "name" {
  value = "${var.name}"
}

output "domain" {
  value = "${var.domain}"
}

output "backend" {
  value = "${module.app.backend}"
}

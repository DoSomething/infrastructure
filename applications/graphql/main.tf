# This template builds a GraphQL application instance.
#
# Manual setup steps:
#   - Create a Gambit Contentful API key for this application, and copy the generated value
#     for '/{name}/contentful/gambit-content-api-key' into SSM.
#   - Set the '{ENV}_NORTHSTAR_AUTH_ID' and '{ENV}_NORTHSTAR_AUTH_SECRET'
#     config vars to allow login for the GraphiQL interface.
#   - Set 'PRODUCTION_GAMBIT_CONVERSATIONS_USER' and 'PRODUCTION_GAMBIT_CONVERSATIONS_PASS'
#     to the appropriate credentials.
#   - Set 'APOLLO_ENGINE_API_KEY' to the Apollo Engine API key for this environment.
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
  description = "The domain this application will be accessible at, e.g. identity.dosomething.org"
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

locals {
  # Environment (e.g. 'dev' or 'DEV')
  env = "${var.environment == "development" ? "dev" : var.environment}"
  ENV = "${upper(local.env)}"
}

resource "random_string" "app_secret" {
  length = 32
}

module "app" {
  source = "../../shared/heroku_app"

  stack       = "express"
  name        = "${var.name}"
  domain      = "${var.domain}"
  pipeline    = "${var.pipeline}"
  environment = "${var.environment}"

  config_vars = {
    APP_SECRET = "${random_string.app_secret.result}"

    # TODO: Update application to expect 'development' here.
    QUERY_ENV = "${local.env}"
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

# This template builds a Phoenix application instance.
#
# Manual setup steps:
#   - Create a Contentful API key for this application, and copy the generated values for both
#     '/{name}/contentful/content-api-key' & '/{name}/contentful/preview-api-key' into SSM.
#   - Set 'FACEBOOK_APP_ID', 'FACEBOOK_APP_SECRET', and 'FACEBOOK_REDIRECT_URL'
#     to the appropriate settings for this app from <developers.facebook.com>.
#   - Set 'APP_KEY' by running 'php artisan generate:key'.
#   - Set 'BERTLY_API_KEY', 'BERTLY_URL', 'CUSTOMER_IO_ID', 'GOOGLE_ANALYTICS_ID',
#     'GRAPHQL_URL', 'NORTHSTAR_AUTHORIZATION_ID', 'NORTHSTAR_AUTHORIZATION_SECRET',
#     'NORTHSTAR_URL', 'NPS_SURVEY_ENABLED', 'PUCK_URL', 'ROGUE_URL', 'SIXPACK_BASE_URL',
#     'SIXPACK_COOKIE_PREFIX', 'SIXPACK_ENABLED', and 'VOTER_REG_MODAL_ENABLED'.
#   - Finally, set '/newrelic/api-key' in SSM to the New Relic API Key, if using.
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
  description = "The domain this application will be accessible at, e.g. www.dosomething.org"
}

variable "name" {
  description = "The application name."
}

variable "papertrail_destination" {
  description = "The Papertrail log destination for this application."
}

# Optional variables:
variable "web_size" {
  # See usage below for default fallback. <https://stackoverflow.com/a/51758050/811624>
  description = "Optionally, override the Heroku dyno type for web processes."
  default     = ""
}

variable "use_contentful_preview_api" {
  description = "Should we use Contentful's Preview API for this app?"
  default     = false
}

variable "with_newrelic" {
  # See usage below for default fallback. <https://stackoverflow.com/a/51758050/811624>
  description = "Should New Relic be enabled for this app? Enabled by default on prod."
  default     = ""
}

data "aws_ssm_parameter" "contentful_space_id" {
  # All environments of this application use the same space.
  name = "/contentful/phoenix/space-id"
}

data "aws_ssm_parameter" "contentful_api_key" {
  # Grab the key for either Contentful's Content or Preview API, based on 'use_contentful_preview_api'.
  name = "/${var.name}/contentful/${var.use_contentful_preview_api ? "preview" : "content"}-api-key"
}

locals {
  # Map environment names to their corresponding "branches"
  # on Contentful (e.g. they use 'master' for production).
  contentful_environments = {
    production  = "master"
    qa          = "qa"
    development = "dev"
  }

  contentful_config_vars = {
    CONTENTFUL_ENVIRONMENT_ID  = "${local.contentful_environments[var.environment]}"
    CONTENTFUL_SPACE_ID        = "${data.aws_ssm_parameter.contentful_space_id.value}"
    CONTENTFUL_CONTENT_API_KEY = "${data.aws_ssm_parameter.contentful_api_key.value}"
    CONTENTFUL_USE_PREVIEW_API = "${var.use_contentful_preview_api}"
    CONTENTFUL_CACHE           = "${var.environment == "production"}"
  }
}

module "app" {
  source = "../../shared/laravel_app"

  name        = "${var.name}"
  domain      = "${var.domain}"
  pipeline    = "${var.pipeline}"
  environment = "${var.environment}"

  # TODO: Add 'module.database.config_vars' once we've migrated
  # records over to the new database instance.
  config_vars = "${merge(
    local.contentful_config_vars
  )}"

  web_size = "${coalesce(var.web_size, var.environment == "production" ? "Performance-M" : "Hobby")}"

  queue_scale = 0

  with_redis = true
  redis_type = "${var.environment == "production" ? "premium-1" : "hobby-dev"}"

  papertrail_destination = "${var.papertrail_destination}"
  with_newrelic          = "${coalesce(var.with_newrelic, var.environment == "production")}"
}

module "database" {
  source = "../../shared/mariadb_instance"

  name           = "${var.name}"
  instance_class = "${var.environment == "production" ? "db.t2.medium" : "db.t2.micro"}"
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

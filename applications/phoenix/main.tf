# This template builds a Phoenix application instance.
#
# Require SSM parameters for Contentful:
#   - /contentful/phoenix/space-id
#   - /{name}/contentful/content-api-key
#   - /{name}/contentful/preview-api-key
#
# Required SSM parameter if using New Relic:
#   - /newrelic/api-key

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
  # Grab the key for either Contentful's Content or Preview API, based on 'use_contentful_preview' setting.
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
  instance_class = "${var.environment == "production" ? "db.t2.large" : "db.t2.micro"}"
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

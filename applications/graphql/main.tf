# This template builds a Northstar application instance.
#
# Manual setup steps:
#  - ...
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

locals {
  # Environment (e.g. 'dev' or 'DEV')
  env = "${var.environment == "development" ? "dev" : var.environment}"
  ENV = "${upper(local.env)}"
}

module "app" {
  source = "../../shared/heroku_app"

  stack       = "express"
  name        = "${var.name}"
  domain      = "${var.domain}"
  pipeline    = "${var.pipeline}"
  environment = "${var.environment}"

  config_vars = {
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

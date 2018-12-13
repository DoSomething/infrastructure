# This template builds a Northstar application instance.
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
  description = "The domain this application will be accessible at, e.g. identity.dosomething.org"
}

variable "name" {
  description = "The application name."
}

variable "papertrail_destination" {
  description = "The Papertrail log destination for this application."
}

variable "with_newrelic" {
  # See usage below for default fallback. <https://stackoverflow.com/a/51758050/811624>
  description = "Should New Relic be enabled for this app? Enabled by default on prod."
  default     = ""
}

locals {}

module "app" {
  source = "../../shared/laravel_app"

  name        = "${var.name}"
  domain      = "${var.domain}"
  pipeline    = "${var.pipeline}"
  environment = "${var.environment}"

  # We use autoscaling in production, so don't try to manage dynos there.
  ignore_web = "${var.environment == "production"}"

  # We don't run a queue process on development right now. @TODO: Should we?
  queue_scale = "${var.environment == "development" ? 0 : 1}"

  with_redis = true
  redis_type = "${var.environment == "production" ? "premium-1" : "hobby-dev"}"

  papertrail_destination = "${var.papertrail_destination}"
  with_newrelic          = "${coalesce(var.with_newrelic, var.environment == "production")}"
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

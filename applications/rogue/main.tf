# This template builds a Rogue application instance.
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
  description = "The domain this application will be accessible at, e.g. activity.dosomething.org"
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

  web_size  = "${var.environment == "production" ? "Standard-2x" : "Standard-1x"}"
  web_scale = "${var.environment == "production" ? 2 : 1}"

  config_vars = "${merge(
    module.database.config_vars,
    module.storage.config_vars,
    module.iam_user.config_vars,
    module.queue.config_vars
  )}"

  # We don't run a queue process on development right now. @TODO: Should we?
  queue_scale = "${var.environment == "development" ? 0 : 1}"

  with_redis = true

  papertrail_destination = "${var.papertrail_destination}"
  with_newrelic          = "${coalesce(var.with_newrelic, var.environment == "production")}"
}

module "database" {
  source = "../../shared/mariadb_instance"

  name           = "${var.name}"
  instance_class = "${var.environment == "production" ? "db.m4.large" : "db.t2.medium"}"
}

module "iam_user" {
  source = "../../shared/iam_app_user"
  name   = "${var.name}"
}

module "queue" {
  source = "../../shared/sqs_queue"
  name   = "${var.name}"
  user   = "${module.iam_user.name}"
}

module "storage" {
  source = "../../shared/s3_bucket"
  name   = "${var.name}"
  user   = "${module.iam_user.name}"
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

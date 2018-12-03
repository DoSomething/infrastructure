# This template builds a Longshot application instance, with
# database, queue, caching, and storage resources. Be sure to
# set the application's required SSM parameters before
# provisioning a new application as well:
#   - /{name}/rds/username
#   - /{name}/rds/password
#   - /mandrill/api-key
#
# And required if using New Relic:
#   - /newrelic/api-key

# Required variables:
variable "environment" {
  description = "The environment for this applicaiton: development, qa, or production."
}

variable "pipeline" {
  description = "The Heroku pipeline ID this application should be created in."
}

variable "name" {
  description = "The application name."
}

variable "domain" {
  description = "The domain this application will be accessible at, e.g. longshot.dosomething.org"
}

variable "email_name" {
  description = "The default 'from' name for this application's mail driver."
}

variable "email_address" {
  description = "The default email address for this application's mail driver."
}

variable "papertrail_destination" {
  description = "The Papertrail log destination for this application."
}

data "aws_ssm_parameter" "mandrill_api_key" {
  name = "/mandrill/api-key"
}

# ----------------------------------------------------

locals {
  # Environment variables for configuring Mandrill:
  mail_config = {
    MAIL_DRIVER     = "mandrill"
    MAIL_HOST       = "smtp.mandrillapp.com"
    EMAIL_NAME      = "${var.email_name}"
    EMAIL_ADDRESS   = "${var.email_address}"
    MANDRILL_APIKEY = "${data.aws_ssm_parameter.mandrill_api_key.value}"
  }
}

module "app" {
  source = "../../shared/laravel_app"

  name        = "${var.name}"
  domain      = "${var.domain}"
  pipeline    = "${var.pipeline}"
  environment = "${var.environment}"

  config_vars = "${merge(
    module.database.laravel_config,
    module.queue.laravel_config,
    module.storage.laravel_config,
    module.iam_user.laravel_config,
    local.mail_config
  )}"

  web_scale   = 1
  queue_scale = 1

  with_redis = true

  papertrail_destination = "${var.papertrail_destination}"
  with_newrelic          = "${var.environment == "production"}"
}

module "database" {
  source = "../../shared/rds_instance"

  name              = "${var.name}"
  instance_class    = "${var.environment == "production" ? "db.t2.medium" : "db.t2.micro"}"
  allocated_storage = "${var.environment == "production" ? 100 : 5}"
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

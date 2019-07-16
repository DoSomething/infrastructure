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
  description = "The environment for this application: development, qa, or production."
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

variable "with_newrelic" {
  # See usage below for default fallback. <https://stackoverflow.com/a/51758050/811624>
  description = "Should New Relic be enabled for this app? Enabled by default on prod."
  default     = ""
}

data "aws_ssm_parameter" "mandrill_api_key" {
  name = "/mandrill/api-key"
}

locals {
  # Environment variables for configuring Mandrill:
  mail_config_vars = {
    MAIL_DRIVER     = "mandrill"
    MAIL_HOST       = "smtp.mandrillapp.com"
    EMAIL_NAME      = var.email_name
    EMAIL_ADDRESS   = var.email_address
    MANDRILL_APIKEY = data.aws_ssm_parameter.mandrill_api_key.value
  }
}

module "app" {
  source = "../../components/heroku_app"

  framework   = "laravel"
  name        = var.name
  domain      = var.domain
  pipeline    = var.pipeline
  environment = var.environment

  config_vars = merge(
    module.database.config_vars,
    module.queue.config_vars,
    module.storage.config_vars,
    module.iam_user.config_vars,
    local.mail_config_vars,
  )

  web_scale   = 1
  queue_scale = 1

  with_redis = true

  papertrail_destination = var.papertrail_destination
  with_newrelic          = coalesce(var.with_newrelic, var.environment == "production")
}

module "database" {
  source = "../../components/mariadb_instance"

  name              = var.name
  environment       = var.environment
  database_name     = "longshot"
  instance_class    = var.environment == "production" ? "db.t2.medium" : "db.t2.micro"
  allocated_storage = var.environment == "production" ? 100 : 5

  subnet_group    = "default-vpc-7899331d"
  security_groups = ["sg-c9a37db2"]
}

module "iam_user" {
  source = "../../components/iam_app_user"
  name   = var.name
}

module "queue" {
  source = "../../components/sqs_queue"
  name   = var.name
  user   = module.iam_user.name
}

module "storage" {
  source = "../../components/s3_bucket"
  name   = var.name
  user   = module.iam_user.name
}

output "name" {
  value = var.name
}

output "domain" {
  value = var.domain
}

output "backend" {
  value = module.app.backend
}


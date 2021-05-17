# This template builds a Northstar application instance.
#
# Manual setup steps:
#   - Set '/mandrill/api-key' to the Mandrill API Key.
#   - Set '/newrelic/api-key' to the New Relic API Key, if using.
#   - Configure a MongoDB Atlas database & set credentials in
#     '/{name}/mongoatlas/host', '/{name}/mongoatlas/database',
#     '/{name}/mongoatlas/username' & '/{name}/mongoatlas/password'.
#   - Set 'FACEBOOK_APP_ID', 'FACEBOOK_APP_SECRET', and 'FACEBOOK_REDIRECT_URL'
#     to the appropriate settings for this app from <developers.facebook.com>.
#   - Set 'BLINK_URL', 'BLINK_USERNAME', and 'BLINK_PASSWORD' if using
#     Blink, and set 'DS_ENABLE_BLINK' environment variable to 'true'.
#   - Set 'APP_AUTH_KEY' by running `vendor/bin/generate-defuse-key`
#     script from within this application, and 'APP_KEY' by running
#     'php artisan generate:key'.
#   - Finally, head to the S3 Bucket in AWS after provisioning, and go to the
#     Permissions -> Public Access Settings screen. Check all the options.
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

variable "storage_name" {
  description = "The storage bucket name."
}

variable "backup_storage_bucket" {
  description = "Optionally, the bucket to replicate storage backups to."
  default     = null
}

variable "papertrail_destination" {
  description = "The Papertrail log destination for this application."
}

variable "with_newrelic" {
  # See usage below for default fallback. <https://stackoverflow.com/a/51758050/811624>
  description = "Should New Relic be enabled for this app? Enabled by default on prod."
  default     = ""
}

data "aws_ssm_parameter" "database_host" {
  name = "/${var.name}/mongoatlas/host"
}

data "aws_ssm_parameter" "database_name" {
  name = "/${var.name}/mongoatlas/database"
}

data "aws_ssm_parameter" "database_username" {
  name = "/${var.name}/mongoatlas/username"
}

data "aws_ssm_parameter" "database_password" {
  name = "/${var.name}/mongoatlas/password"
}

data "aws_ssm_parameter" "mandrill_api_key" {
  name = "/mandrill/api-key"
}

resource "random_string" "callpower_api_key" {
  length = 32
}

resource "random_string" "softedge_api_key" {
  length = 32
}

locals {
  database_config_vars = {
    DB_HOST      = data.aws_ssm_parameter.database_host.value
    DB_NAME      = data.aws_ssm_parameter.database_name.value
    DB_USERNAME  = data.aws_ssm_parameter.database_username.value
    DB_PASSWORD  = data.aws_ssm_parameter.database_password.value
    DB_PORT      = 27017
    DB_AUTH_NAME = "admin"
    DB_SSL       = true
  }

  mail_config_vars = {
    MAIL_DRIVER     = "mandrill"
    MAIL_HOST       = "smtp.mandrillapp.com"
    EMAIL_NAME      = "DoSomething.org"
    EMAIL_ADDRESS   = "no-reply@dosomething.org"
    MANDRILL_SECRET = data.aws_ssm_parameter.mandrill_api_key.value
  }

  secret_config_vars = {
    CALLPOWER_API_KEY = random_string.callpower_api_key.result
    SOFTEDGE_API_KEY  = random_string.softedge_api_key.result
  }

  queue_low_config_vars = {
    SQS_LOW_PRIORITY_QUEUE = module.queue_low.id
  }

  feature_config_vars = {
    DS_ENABLE_PASSWORD_GRANT = false
    DS_ENABLE_RATE_LIMITING  = true
    DS_ENABLE_CUSTOMER_IO    = var.environment != "development"
  }

  # This application is part of our backend stack.
  stack = "backend"
}

module "app" {
  source = "../../components/heroku_app"

  framework   = "laravel"
  name        = var.name
  domain      = var.domain
  pipeline    = var.pipeline
  environment = var.environment

  config_vars = merge(
    module.iam_user.config_vars,
    module.storage.config_vars,
    module.queue_high.config_vars,
    local.queue_low_config_vars,
    local.database_config_vars,
    local.feature_config_vars,
    local.mail_config_vars,
    local.secret_config_vars,
  )

  # We use autoscaling in production, so don't try to manage dynos there.
  ignore_web = var.environment == "production"

  queue_scale = 1

  with_redis = true

  papertrail_destination = var.papertrail_destination
  with_newrelic          = coalesce(var.with_newrelic, var.environment == "production")
}

module "iam_user" {
  source = "../../components/iam_app_user"
  name   = var.name
}

module "queue_high" {
  source = "../../components/sqs_queue"

  application = var.name
  name        = "${var.name}-high"
  environment = var.environment
  stack       = local.stack

  user = module.iam_user.name
}

module "queue_low" {
  source = "../../components/sqs_queue"

  application = var.name
  name        = "${var.name}-low"
  environment = var.environment
  stack       = local.stack

  user = module.iam_user.name
}

module "storage" {
  source = "../../components/s3_bucket"

  application = var.name
  name        = var.storage_name
  environment = var.environment
  stack       = local.stack
  user        = module.iam_user.name

  private            = true
  replication_target = var.backup_storage_bucket
  versioning         = var.environment == "production"
  temporary_paths    = ["temporary/"]
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


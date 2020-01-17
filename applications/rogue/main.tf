# This template builds a Rogue application instance.
#
# To create a new Rogue instance, 
#   1. Configure this module's variable arguments & apply.
#   2. The initial apply will fail trying to create 'heroku_formation' resources
#      because code hasn't been deployed. Deploy this application's `master` branch
#      via Heroku's web interface & then re-run the apply.
#   3. Generate an 'APP_KEY' by running 'php artisan generate:key' on a local instance of
#      this application. Copy-paste that value into `APP_KEY` in Heroku's web interface.
#   4. Create app-specific user & machine OAuth clients (via Aurora) and set the
#      appropriate values for the 'NORTHSTAR_AUTH_ID', 'NORTHSTAR_AUTH_SECRET',
#      'NORTHSTAR_CLIENT_ID', and 'NORTHSTAR_CLIENT_SECRET' environment vars.
#   5. Set 'BLINK_URL', 'BLINK_USERNAME', and 'BLINK_PASSWORD' if using
#      Blink, and set 'DS_ENABLE_BLINK' environment variable to 'true'.
#   6. Set 'FASTLY_API_TOKEN', 'FASTLY_SERVICE_ID' for the an app-specific Fastly
#      API Key with the 'global:read' and 'purge_select' permissions.
#   7. Rename this app's Papertrail system (e.g. 'dosomething-rogue-qa' instead of
#      'd.aed4c-371c-81f5-93d91'), here: <https://papertrailapp.com/groups/4485452>
#
# If configuring a production instance:
#   8. Set 'SLACK_ENDPOINT' & 'SLACK_WEBHOOK_INTEGRATION_URL' for #notify-badass-members integration.
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
  description = "The domain this application will be accessible at, e.g. activity.dosomething.org"
}

variable "name" {
  description = "The application name."
}

variable "papertrail_destination" {
  description = "The Papertrail log destination for this application."
}

variable "backup_storage_bucket" {
  description = "Optionally, the bucket to replicate storage backups to."
  default     = null
}

variable "deprecated" {
  description = "Deprecate this app, removing database users & allowing deletion."
  default     = false
}

variable "with_newrelic" {
  # See usage below for default fallback. <https://stackoverflow.com/a/51758050/811624>
  description = "Should New Relic be enabled for this app? Enabled by default on prod."
  default     = ""
}

locals {
  # TODO: Remove these once application is updated to use new vars.
  legacy_config_vars = {
    S3_KEY                = module.iam_user.config_vars["AWS_ACCESS_KEY"]
    S3_SECRET             = module.iam_user.config_vars["AWS_SECRET_KEY"]
    SQS_ACCESS_KEY_ID     = module.iam_user.config_vars["AWS_ACCESS_KEY"]
    SQS_SECRET_ACCESS_KEY = module.iam_user.config_vars["AWS_SECRET_KEY"]
  }
}

module "app" {
  source = "../../components/heroku_app"

  framework   = "laravel"
  name        = var.name
  domain      = var.domain
  pipeline    = var.pipeline
  environment = var.environment

  web_size = var.environment == "production" ? "Standard-2x" : "Standard-1x"

  # We use autoscaling in production, so don't try to manage dynos there.
  ignore_web = var.environment == "production"

  config_vars = merge(
    module.database.config_vars,
    module.queue.config_vars,
    module.iam_user.config_vars,
    module.storage.config_vars,
    local.legacy_config_vars,
  )

  # We don't run a queue process on development right now. @TODO: Should we?
  queue_scale = var.environment == "development" ? 0 : 1

  with_redis = true

  papertrail_destination = var.papertrail_destination
  with_newrelic          = coalesce(var.with_newrelic, var.environment == "production")
}

module "database" {
  source = "../../components/mariadb_instance"

  name           = var.name
  environment    = var.environment
  instance_class = var.environment == "production" ? "db.m4.large" : "db.t2.medium"
  multi_az       = var.environment == "production"
  is_dms_source  = true
  deprecated     = var.deprecated
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

  replication_target = var.backup_storage_bucket
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


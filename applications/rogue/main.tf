# This template builds a Rogue application instance.
#
# To create a new Rogue instance, 
#   1. Configure a new 'rogue' module with the required variable arguments & apply.
#   2. The initial apply will fail trying to create 'heroku_formation' resources
#      because code hasn't been deployed. Deploy this application's `master` branch
#      via Heroku's web interface & then re-run the apply. It should be successful.
#   3. Create app-specific user & machine OAuth clients (via Aurora) and set the
#      appropriate values for the 'NORTHSTAR_AUTH_ID', 'NORTHSTAR_AUTH_SECRET',
#      'NORTHSTAR_CLIENT_ID', and 'NORTHSTAR_CLIENT_SECRET' environment vars.
#   4. If using Blink (for Customer.io), set 'BLINK_USERNAME' and 'BLINK_PASSWORD'
#      via LastPass & set 'DS_ENABLE_BLINK' environment variable to 'true'.
#   5. Set 'FASTLY_SERVICE_ID' to the appropriate Fastly service for this environment.
#   6. Create an app-specific Fastly API Key with the 'global:read' and 'purge_select'
#      permissions <https://manage.fastly.com/account/personal/tokens> and set that 
#      secret in the 'FASTLY_API_TOKEN' environment variable.
#   7. Rename this app's Papertrail system (e.g. 'dosomething-rogue-qa' instead of
#      'd.aed4c-371c-81f5-93d91'), here: <https://papertrailapp.com/groups/4485452>
#   8. When setting up a new Rogue RDS instance or restoring an instance from backups
#      make sure, as the mysql admin user, to run the following command:
#      `call mysql.rds_set_configuration('binlog retention hours', 24);`
#      This is required for the Data team's Fivetran connector to pull incremental data
#      changes. More details here <https://www.pivotaltracker.com/story/show/170956852> .
#
# If configuring a production instance:
#   9. Set 'SLACK_WEBHOOK_INTEGRATION_URL' for #notify-badass-members integration.
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

variable "northstar_url" {
  description = "The Northstar URL for this environment."
}

variable "graphql_url" {
  description = "The GraphQL gateway URL for this environment."
}

variable "blink_url" {
  description = "The Blink URL for this environment."
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

resource "random_id" "app_key" {
  byte_length = 32
}

locals {
  extra_config_vars = {
    # TODO: Merge this into the 'heroku_app' module's Laravel env vars?
    APP_KEY = "base64:${random_id.app_key.b64_std}"

    # Services this application relies on:
    NORTHSTAR_URL = var.northstar_url
    GRAPHQL_URL   = var.graphql_url
    BLINK_URL     = var.blink_url
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
    local.extra_config_vars,
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


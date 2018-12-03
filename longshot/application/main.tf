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

# Optional variables:
variable "web_size" {
  description = "The Heroku dyno type for web processes."
  default     = "Standard-1X"
}

variable "web_scale" {
  description = "The number of web dynos this application should have."
  default     = "1"
}

variable "queue_size" {
  description = "The Heroku dyno type for queue processes."
  default     = "Standard-1X"
}

variable "queue_scale" {
  description = "The number of queue dynos this application should have."
  default     = "1"
}

variable "redis_type" {
  description = "The Heroku Redis add-on plan. See: https://goo.gl/3v3RXX"
  default     = "hobby-dev"
}

variable "with_newrelic" {
  description = "Should New Relic be configured for this app? Generally only used on prod."
  default     = false
}

data "aws_ssm_parameter" "mandrill_api_key" {
  name = "/mandrill/api-key"
}

data "aws_ssm_parameter" "newrelic_api_key" {
  count = "${var.with_newrelic ? 1 : 0}"
  name  = "/newrelic/api-key"
}

# ----------------------------------------------------

resource "heroku_app" "app" {
  name   = "${var.name}"
  region = "us"

  organization {
    name = "dosomething"
  }

  config_vars {
    # App settings:
    APP_ENV                    = "${var.environment}"
    APP_DEBUG                  = "false"
    APP_LOG                    = "errorlog"
    APP_URL                    = "https://${var.domain}"
    TRUSTED_PROXY_IP_ADDRESSES = "**"

    # Drivers:
    QUEUE_DRIVER   = "sqs"
    CACHE_DRIVER   = "redis"
    SESSION_DRIVER = "redis"
    STORAGE_DRIVER = "s3"
    MAIL_DRIVER    = "mandrill"

    # Email:
    EMAIL_NAME      = "${var.email_name}"
    EMAIL_ADDRESS   = "${var.email_address}"
    MAIL_HOST       = "smtp.mandrillapp.com"
    MANDRILL_APIKEY = "${data.aws_ssm_parameter.mandrill_api_key.value}"

    # Database:
    DB_HOST     = "${module.database.address}"
    DB_PORT     = "${module.database.port}"
    DB_DATABASE = "${module.database.name}"
    DB_USERNAME = "${module.database.username}"
    DB_PASSWORD = "${module.database.password}"

    # S3 Bucket & SQS Queue:
    AWS_ACCESS_KEY    = "${module.iam_user.id}"
    AWS_SECRET_KEY    = "${module.iam_user.secret}"
    SQS_DEFAULT_QUEUE = "${module.sqs_queue.id}"
    S3_REGION         = "${module.storage.region}"
    S3_BUCKET         = "${module.storage.id}"

    # New Relic:
    NEW_RELIC_ENABLED   = "${var.with_newrelic ? "true" : "false"}"
    NEW_RELIC_APP_NAME  = "${var.with_newrelic ? var.name : ""}"
    NEW_RELIC_LOG_LEVEL = "error"

    # We can't use a ternary on an optional resource, hence this hack! https://git.io/fp2pg
    NEW_RELIC_LICENSE_KEY = "${join("", data.aws_ssm_parameter.newrelic_api_key.*.value)}"

    # Additional secrets, set manually:
    # APP_KEY = ...
  }

  buildpacks = [
    "heroku/nodejs",
    "heroku/php",
  ]

  acm = true
}

resource "heroku_formation" "web" {
  app      = "${heroku_app.app.name}"
  type     = "web"
  size     = "${var.web_size}"
  quantity = "${var.web_scale}"
}

resource "heroku_formation" "queue" {
  app      = "${heroku_app.app.name}"
  type     = "queue"
  size     = "${var.queue_size}"
  quantity = "${var.queue_scale}"
}

resource "heroku_domain" "domain" {
  app      = "${heroku_app.app.name}"
  hostname = "${var.domain}"
}

resource "heroku_drain" "papertrail" {
  app = "${heroku_app.app.name}"
  url = "syslog+tls://${var.papertrail_destination}"
}

resource "heroku_pipeline_coupling" "app" {
  app      = "${heroku_app.app.name}"
  pipeline = "${var.pipeline}"

  # Heroku uses "staging" for what we call "qa":
  stage = "${var.environment == "qa" ? "staging" : var.environment}"
}

resource "heroku_addon" "redis" {
  app  = "${heroku_app.app.name}"
  plan = "heroku-redis:${var.redis_type}"
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
  value = "${heroku_app.app.heroku_hostname}"
}

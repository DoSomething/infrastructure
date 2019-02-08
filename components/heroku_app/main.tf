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

variable "framework" {
  description = "The framework for this application (e.g. 'laravel', 'express')."
}

variable "papertrail_destination" {
  description = "The Papertrail log destination for this application."
}

variable "domain" {
  description = "The domain this application will be accessible at, e.g. longshot.dosomething.org"
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

variable "ignore_web" {
  description = "Should we manage the web dyno with Terraform? Set to 'true' if auto-scaling."
  default     = false
}

variable "queue_size" {
  description = "The Heroku dyno type for queue processes."
  default     = "Standard-1X"
}

variable "queue_scale" {
  description = "The number of queue dynos this application should have."
  default     = "1"
}

variable "config_vars" {
  description = "Environment variables for this application."
  default     = {}
}

variable "with_newrelic" {
  description = "Should New Relic be configured for this app? Generally only used on prod."
  default     = false
}

variable "with_redis" {
  description = "Should we create a Redis store for this application?"
  default     = false
}

variable "redis_type" {
  # See usage below for default value. <https://stackoverflow.com/a/51758050/811624>
  description = "The Heroku Redis add-on plan. See: https://goo.gl/3v3RXX"
  default     = ""
}

data "aws_ssm_parameter" "newrelic_api_key" {
  count = "${var.with_newrelic ? 1 : 0}"
  name  = "/newrelic/api-key"
}

data "aws_ssm_parameter" "slack_deploy_webhook" {
  count = "${var.environment == "production" ? 1 : 0}"
  name  = "/slack/deploys-webhook"
}

locals {
  config_vars = {
    express = {
      APP_URL   = "https://${var.domain}"
      APP_ENV   = "${var.environment}"
      NODE_ENV  = "production"
      LOG_LEVEL = "info"

      # New Relic (if enabled for this app):
      NEW_RELIC_ENABLED     = "${var.with_newrelic ? "true" : "false"}"
      NEW_RELIC_APP_NAME    = "${var.with_newrelic ? var.name : ""}"
      NEW_RELIC_LICENSE_KEY = "${join("", data.aws_ssm_parameter.newrelic_api_key.*.value)}" # optional! <https://git.io/fp2pg>
      NEW_RELIC_LOG_LEVEL   = "error"
    }

    laravel = {
      APP_URL = "https://${var.domain}"

      # Set environment & ensure app isn't in debug mode:
      APP_ENV   = "${var.environment}"
      APP_DEBUG = "false"

      # Configure logging for Heroku drain:
      APP_LOG = "errorlog"

      # Alongside the Trusted Proxy module, this allows us to use SSL behind
      # Heroku's load balancer. Heroku strips these headers on incoming traffic
      # so it's safe to trust all (and we can't know their specific IPs).
      TRUSTED_PROXY_IP_ADDRESSES = "**"

      # If we're using Redis for this app, tell Laravel to use that for cache & session store.
      CACHE_DRIVER   = "${var.with_redis ? "redis" : "file"}"
      SESSION_DRIVER = "${var.with_redis ? "redis" : "file"}"

      # New Relic (if enabled for this app):
      NEW_RELIC_ENABLED     = "${var.with_newrelic ? "true" : "false"}"
      NEW_RELIC_APP_NAME    = "${var.with_newrelic ? var.name : ""}"
      NEW_RELIC_LICENSE_KEY = "${join("", data.aws_ssm_parameter.newrelic_api_key.*.value)}" # optional! <https://git.io/fp2pg>
      NEW_RELIC_LOG_LEVEL   = "error"
    }
  }

  # By default, use a paid Heroku Redis add-on plan, with 50MB storage and high
  # availability, for production instances. Can be overridden with var.redis_type.
  redis_default = "${var.environment == "production" ? "premium-0" : "hobby-dev"}"

  # Decide which buildpacks to use based on our framework:
  buildpacks = {
    express = [
      "heroku/nodejs",
    ]

    laravel = [
      "heroku/nodejs",
      "heroku/php",
    ]
  }
}

resource "heroku_app" "app" {
  name   = "${var.name}"
  region = "us"

  organization {
    name = "dosomething"
  }

  config_vars = ["${merge(local.config_vars[var.framework], var.config_vars)}"]

  buildpacks = "${local.buildpacks[var.framework]}"

  acm = true
}

resource "heroku_formation" "web" {
  count    = "${var.ignore_web ? 0 : 1}"
  app      = "${heroku_app.app.name}"
  type     = "web"
  size     = "${var.web_size}"
  quantity = "${var.web_scale}"
}

resource "heroku_formation" "queue" {
  count    = "${var.queue_scale != 0 ? 1 : 0}"
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

resource "heroku_addon" "webhook" {
  count = "${var.environment == "production" ? 1 : 0}"
  app   = "${heroku_app.app.name}"
  plan  = "deployhooks:http"

  config {
    url = "${data.aws_ssm_parameter.slack_deploy_webhook.value}"
  }
}

resource "heroku_addon" "redis" {
  count = "${var.with_redis ? 1 : 0}"
  app   = "${heroku_app.app.name}"
  plan  = "heroku-redis:${coalesce(var.redis_type, local.redis_default)}"
}

output "backend" {
  value = "${heroku_app.app.heroku_hostname}"
}

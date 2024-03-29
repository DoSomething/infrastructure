data "aws_ssm_parameter" "newrelic_api_key" {
  count = var.with_newrelic ? 1 : 0
  name  = "/newrelic/api-key"
}

data "aws_ssm_parameter" "slack_deploy_webhook" {
  count = var.environment == "production" ? 1 : 0
  name  = "/slack/deploys-webhook"
}

locals {
  config_vars = {
    express = {
      APP_URL   = "https://${var.domain}"
      APP_ENV   = var.environment
      NODE_ENV  = "production"
      LOG_LEVEL = "info"

      # New Relic (if enabled for this app):
      NEW_RELIC_ENABLED     = var.with_newrelic ? "true" : "false"
      NEW_RELIC_APP_NAME    = var.with_newrelic ? var.name : ""
      NEW_RELIC_LICENSE_KEY = join("", data.aws_ssm_parameter.newrelic_api_key.*.value) # optional! <https://git.io/fp2pg>
      NEW_RELIC_LOG_LEVEL   = "error"
    }

    laravel = {
      APP_URL = "https://${var.domain}"

      # Set environment & ensure app isn't in debug mode:
      APP_ENV   = var.environment
      APP_DEBUG = "false"

      # Configure logging for Heroku drain. (The 'APP_LOG' environment variable
      # is used in Laravel 5.5, and LOG_CHANNEL is used in Laravel 5.6+).
      APP_LOG     = "errorlog"
      LOG_CHANNEL = "errorlog"

      # Alongside the Trusted Proxy module, this allows us to use SSL behind
      # Heroku's load balancer. Heroku strips these headers on incoming traffic
      # so it's safe to trust all (and we can't know their specific IPs).
      TRUSTED_PROXY_IP_ADDRESSES = "**"

      # If we're using Redis for this app, tell Laravel to use that for cache & session store.
      CACHE_DRIVER   = var.with_redis ? "redis" : "file"
      SESSION_DRIVER = var.with_redis ? "redis" : "file"

      # New Relic (if enabled for this app):
      NEW_RELIC_ENABLED     = var.with_newrelic ? "true" : "false"
      NEW_RELIC_APP_NAME    = var.with_newrelic ? var.name : ""
      NEW_RELIC_LICENSE_KEY = join("", data.aws_ssm_parameter.newrelic_api_key.*.value) # optional! <https://git.io/fp2pg>
      NEW_RELIC_LOG_LEVEL   = "error"
    }
  }

  # By default, use a paid Heroku Redis add-on plan, with 50MB storage and high availability
  # for our production & QA instances. This can be overridden with var.redis_type.
  redis_default = var.environment != "development" ? "premium-0" : "hobby-dev"

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
  name   = var.name
  region = "us"

  organization {
    name = "dosomething"
  }

  config_vars = merge(local.config_vars[var.framework], var.config_vars)

  buildpacks = local.buildpacks[var.framework]

  acm = true
}

resource "heroku_formation" "web" {
  count    = var.ignore_web ? 0 : 1
  app      = heroku_app.app.name
  type     = "web"
  size     = var.web_size
  quantity = var.web_scale
}

resource "heroku_formation" "queue" {
  count    = var.queue_scale != 0 ? 1 : 0
  app      = heroku_app.app.name
  type     = "queue"
  size     = var.queue_size
  quantity = var.queue_scale
}

resource "heroku_domain" "domain" {
  app      = heroku_app.app.name
  hostname = var.domain
}

resource "heroku_drain" "papertrail" {
  app = heroku_app.app.name
  url = "syslog+tls://${var.papertrail_destination}"
}

resource "heroku_pipeline_coupling" "app" {
  app      = heroku_app.app.name
  pipeline = var.pipeline

  # Heroku uses "staging" for what we call "qa":
  stage = var.environment == "qa" ? "staging" : var.environment
}

resource "heroku_addon" "webhook" {
  count = var.environment == "production" ? 1 : 0
  app   = heroku_app.app.name
  plan  = "deployhooks:http"

  config = {
    url = data.aws_ssm_parameter.slack_deploy_webhook[0].value
  }
}

resource "heroku_addon" "redis" {
  count = var.with_redis ? 1 : 0
  app   = heroku_app.app.name
  plan  = "heroku-redis:${coalesce(var.redis_type, local.redis_default)}"
}
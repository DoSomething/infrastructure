variable "northstar_pipeline" {}
variable "papertrail_destination" {}

resource "heroku_app" "northstar-dev" {
  name   = "dosomething-northstar-dev"
  region = "us"

  organization {
    name = "dosomething"
  }

  config_vars {
    APP_ENV   = "production"
    APP_DEBUG = "false"
    APP_LOG   = "errorlog"
    APP_URL   = "https://identity-dev.dosomething.org"
  }

  buildpacks = [
    "heroku/nodejs",
    "heroku/php",
  ]

  acm = true
}

resource "heroku_formation" "northstar-dev" {
  app      = "${heroku_app.northstar-dev.name}"
  type     = "web"
  size     = "Standard-1X"
  quantity = 1
}

resource "heroku_formation" "northstar-dev-queue" {
  app      = "${heroku_app.northstar-dev.name}"
  type     = "queue"
  size     = "Standard-1X"
  quantity = 0
}

resource "heroku_domain" "northstar-dev" {
  app      = "${heroku_app.northstar-dev.name}"
  hostname = "identity-dev.dosomething.org"
}

resource "heroku_drain" "northstar-dev" {
  app = "${heroku_app.northstar-dev.name}"
  url = "syslog+tls://${var.papertrail_destination}"
}

resource "heroku_pipeline_coupling" "northstar-dev" {
  app      = "${heroku_app.northstar-dev.name}"
  pipeline = "${var.northstar_pipeline}"
  stage    = "development"
}

output "name_dev" {
  value = "${heroku_app.northstar-dev.name}"
}

output "domain_dev" {
  value = "${heroku_domain.northstar-dev.hostname}"
}

output "backend_dev" {
  value = "${heroku_app.northstar-dev.heroku_hostname}"
}

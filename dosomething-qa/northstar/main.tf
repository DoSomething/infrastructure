variable "northstar_pipeline" {}
variable "papertrail_destination" {}

resource "heroku_app" "northstar-qa" {
  name   = "dosomething-northstar-qa"
  region = "us"

  organization {
    name = "dosomething"
  }

  config_vars {
    APP_ENV   = "production"
    APP_DEBUG = "false"
    APP_LOG   = "errorlog"
    APP_URL   = "https://identity-qa.dosomething.org"
  }

  buildpacks = [
    "heroku/nodejs",
    "heroku/php",
  ]

  acm = true
}

resource "heroku_formation" "web" {
  app      = "${heroku_app.northstar-qa.name}"
  type     = "web"
  size     = "Standard-1X"
  quantity = 1
}

resource "heroku_formation" "queue" {
  app      = "${heroku_app.northstar-qa.name}"
  type     = "queue"
  size     = "Standard-1X"
  quantity = 1
}

resource "heroku_domain" "identity-qa" {
  app      = "${heroku_app.northstar-qa.name}"
  hostname = "identity-qa.dosomething.org"
}

resource "heroku_drain" "papertrail" {
  app = "${heroku_app.northstar-qa.name}"
  url = "syslog+tls://${var.papertrail_destination}"
}

resource "heroku_pipeline_coupling" "northstar-qa" {
  app      = "${heroku_app.northstar-qa.name}"
  pipeline = "${var.northstar_pipeline}"
  stage    = "staging"
}

output "name" {
  value = "${heroku_app.northstar-qa.name}"
}

output "domain" {
  value = "${heroku_domain.identity-qa.hostname}"
}

output "backend" {
  value = "${heroku_app.northstar-qa.heroku_hostname}"
}

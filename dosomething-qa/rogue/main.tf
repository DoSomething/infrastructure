variable "rogue_pipeline" {}
variable "papertrail_destination" {}

resource "heroku_app" "rogue-qa" {
  name   = "dosomething-rogue-qa"
  region = "us"

  organization {
    name = "dosomething"
  }

  config_vars {
    APP_ENV   = "production"
    APP_DEBUG = "false"
    APP_LOG   = "errorlog"
    APP_URL   = "https://activity-qa.dosomething.org"
  }

  buildpacks = [
    "heroku/nodejs",
    "heroku/php",
  ]

  acm = true
}

resource "heroku_formation" "rogue-qa" {
  app      = "${heroku_app.rogue-qa.name}"
  type     = "web"
  size     = "Standard-1X"
  quantity = 1
}

resource "heroku_formation" "rogue-qa-queue" {
  app      = "${heroku_app.rogue-qa.name}"
  type     = "queue"
  size     = "Standard-1X"
  quantity = 1
}

resource "heroku_domain" "rogue-qa" {
  app      = "${heroku_app.rogue-qa.name}"
  hostname = "activity-qa.dosomething.org"
}

resource "heroku_drain" "rogue-qa" {
  app = "${heroku_app.rogue-qa.name}"
  url = "syslog+tls://${var.papertrail_destination}"
}

resource "heroku_pipeline_coupling" "rogue-qa" {
  app      = "${heroku_app.rogue-qa.name}"
  pipeline = "${var.rogue_pipeline}"
  stage    = "staging"
}

output "name" {
  value = "${heroku_app.rogue-qa.name}"
}

output "domain" {
  value = "${heroku_domain.rogue-qa.hostname}"
}

output "backend" {
  value = "${heroku_app.rogue-qa.heroku_hostname}"
}

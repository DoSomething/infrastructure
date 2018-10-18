variable "rogue_pipeline" {}
variable "papertrail_destination" {}

resource "heroku_app" "rogue-dev" {
  name   = "dosomething-rogue-dev"
  region = "us"

  organization {
    name = "dosomething"
  }

  config_vars {
    APP_ENV   = "production"
    APP_DEBUG = "false"
    APP_LOG   = "errorlog"
    APP_URL   = "https://activity-dev.dosomething.org"
  }

  buildpacks = [
    "heroku/nodejs",
    "heroku/php",
  ]

  acm = true
}

resource "heroku_formation" "rogue-dev" {
  app      = "${heroku_app.rogue-dev.name}"
  type     = "web"
  size     = "hobby"
  quantity = 1
}

resource "heroku_formation" "rogue-dev-queue" {
  app      = "${heroku_app.rogue-dev.name}"
  type     = "queue"
  size     = "hobby"
  quantity = 0
}

resource "heroku_domain" "rogue-dev" {
  app      = "${heroku_app.rogue-dev.name}"
  hostname = "activity-dev.dosomething.org"
}

resource "heroku_drain" "rogue-dev" {
  app = "${heroku_app.rogue-dev.name}"
  url = "syslog+tls://${var.papertrail_destination}"
}

resource "heroku_pipeline_coupling" "rogue-dev" {
  app      = "${heroku_app.rogue-dev.name}"
  pipeline = "${var.rogue_pipeline}"
  stage    = "development"
}

output "name" {
  value = "${heroku_app.rogue-dev.name}"
}

output "domain" {
  value = "${heroku_domain.rogue-dev.hostname}"
}

output "backend" {
  value = "${heroku_app.rogue-dev.heroku_hostname}"
}

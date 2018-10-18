variable "phoenix_pipeline" {}
variable "papertrail_destination" {}

resource "heroku_app" "phoenix-dev" {
  name   = "dosomething-phoenix-dev"
  region = "us"

  organization {
    name = "dosomething"
  }

  config_vars {
    APP_ENV   = "production"
    APP_DEBUG = "false"
    APP_LOG   = "errorlog"
    APP_URL   = "https://www-dev.dosomething.org"
  }

  buildpacks = [
    "heroku/nodejs",
    "heroku/php",
  ]

  acm = true
}

resource "heroku_formation" "web" {
  app      = "${heroku_app.phoenix-dev.name}"
  type     = "web"
  size     = "Hobby"
  quantity = 1
}

resource "heroku_domain" "www-dev" {
  app      = "${heroku_app.phoenix-dev.name}"
  hostname = "www-dev.dosomething.org"
}

resource "heroku_drain" "papertrail" {
  app = "${heroku_app.phoenix-dev.name}"
  url = "syslog+tls://${var.papertrail_destination}"
}

resource "heroku_pipeline_coupling" "phoenix-dev" {
  app      = "${heroku_app.phoenix-dev.name}"
  pipeline = "${var.phoenix_pipeline}"
  stage    = "development"
}

output "name" {
  value = "${heroku_app.phoenix-dev.name}"
}

output "domain" {
  value = "${heroku_domain.www-dev.hostname}"
}

output "backend" {
  value = "${heroku_app.phoenix-dev.heroku_hostname}"
}

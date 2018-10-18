variable "phoenix_pipeline" {}
variable "papertrail_destination" {}

resource "heroku_app" "phoenix-preview" {
  name   = "dosomething-phoenix-preview"
  region = "us"

  organization {
    name = "dosomething"
  }

  config_vars {
    APP_ENV   = "production"
    APP_DEBUG = "false"
    APP_LOG   = "errorlog"
  }

  buildpacks = [
    "heroku/nodejs",
    "heroku/php",
  ]

  acm = true
}

resource "heroku_formation" "web" {
  app      = "${heroku_app.phoenix-preview.name}"
  type     = "web"
  size     = "Hobby"
  quantity = 1
}

resource "heroku_domain" "www-preview" {
  app      = "${heroku_app.phoenix-preview.name}"
  hostname = "www-preview.dosomething.org"
}

resource "heroku_drain" "papertrail" {
  app = "${heroku_app.phoenix-preview.name}"
  url = "syslog+tls://${var.papertrail_destination}"
}

resource "heroku_pipeline_coupling" "phoenix-preview" {
  app      = "${heroku_app.phoenix-preview.name}"
  pipeline = "${var.phoenix_pipeline}"
  stage    = "production"
}

output "name" {
  value = "${heroku_app.phoenix-preview.name}"
}

output "domain" {
  value = "${heroku_domain.www-preview.hostname}"
}

output "backend" {
  value = "${heroku_app.phoenix-preview.heroku_hostname}"
}

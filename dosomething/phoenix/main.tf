variable "phoenix_pipeline" {}
variable "papertrail_destination" {}

resource "heroku_app" "phoenix" {
  name   = "dosomething-phoenix"
  region = "us"

  organization {
    name = "dosomething"
  }

  config_vars {
    APP_ENV   = "production"
    APP_DEBUG = "false"
    APP_LOG   = "errorlog"
    APP_URL   = "https://www.dosomething.org"
  }

  buildpacks = [
    "heroku/nodejs",
    "heroku/php",
  ]

  acm = true
}

resource "heroku_formation" "phoenix" {
  app      = "${heroku_app.phoenix.name}"
  type     = "web"
  size     = "Performance-M"
  quantity = 1
}

resource "heroku_domain" "phoenix" {
  app      = "${heroku_app.phoenix.name}"
  hostname = "www.dosomething.org"
}

resource "heroku_drain" "phoenix" {
  app = "${heroku_app.phoenix.name}"
  url = "syslog+tls://${var.papertrail_destination}"
}

resource "heroku_pipeline_coupling" "phoenix" {
  app      = "${heroku_app.phoenix.name}"
  pipeline = "${var.phoenix_pipeline}"
  stage    = "production"
}

output "name_dev" {
  value = "${heroku_app.phoenix.name}"
}

output "domain_dev" {
  value = "${heroku_domain.phoenix.hostname}"
}

output "backend_dev" {
  value = "${heroku_app.phoenix.heroku_hostname}"
}

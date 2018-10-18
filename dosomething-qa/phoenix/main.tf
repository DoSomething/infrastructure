variable "phoenix_pipeline" {}
variable "papertrail_destination" {}

resource "heroku_app" "phoenix-qa" {
  name   = "dosomething-phoenix-qa"
  region = "us"

  organization {
    name = "dosomething"
  }

  config_vars {
    APP_ENV   = "production"
    APP_DEBUG = "false"
    APP_LOG   = "errorlog"
    APP_URL   = "https://www-qa.dosomething.org"
  }

  buildpacks = [
    "heroku/nodejs",
    "heroku/php",
  ]

  acm = true
}

resource "heroku_formation" "phoenix-qa" {
  app      = "${heroku_app.phoenix-qa.name}"
  type     = "web"
  size     = "Hobby"
  quantity = 1
}

resource "heroku_domain" "qa" {
  app      = "${heroku_app.phoenix-qa.name}"
  hostname = "qa.dosomething.org"
}

resource "heroku_domain" "www-qa" {
  app      = "${heroku_app.phoenix-qa.name}"
  hostname = "www-qa.dosomething.org"
}

resource "heroku_drain" "phoenix-qa" {
  app = "${heroku_app.phoenix-qa.name}"
  url = "syslog+tls://${var.papertrail_destination}"
}

resource "heroku_pipeline_coupling" "phoenix-qa" {
  app      = "${heroku_app.phoenix-qa.name}"
  pipeline = "${var.phoenix_pipeline}"
  stage    = "staging"
}

output "name_qa" {
  value = "${heroku_app.phoenix-qa.name}"
}

output "domain_qa" {
  value = "${heroku_domain.qa.hostname}"
}

output "backend_qa" {
  value = "${heroku_app.phoenix-qa.heroku_hostname}"
}

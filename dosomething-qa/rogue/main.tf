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

# ----------------------------

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

# ----------------------------

output "name_dev" {
  value = "${heroku_app.rogue-dev.name}"
}

output "domain_dev" {
  value = "${heroku_domain.rogue-dev.hostname}"
}

output "backend_dev" {
  value = "${heroku_app.rogue-dev.heroku_hostname}"
}

output "name_qa" {
  value = "${heroku_app.rogue-qa.name}"
}

output "domain_qa" {
  value = "${heroku_domain.rogue-qa.hostname}"
}

output "backend_qa" {
  value = "${heroku_app.rogue-qa.heroku_hostname}"
}

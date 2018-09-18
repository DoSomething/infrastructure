variable "rogue_pipeline" {}
variable "papertrail_destination" {}

resource "heroku_app" "rogue" {
  name   = "dosomething-rogue"
  region = "us"

  organization {
    name = "dosomething"
  }

  config_vars {
    APP_ENV   = "production"
    APP_DEBUG = "false"
    APP_LOG   = "errorlog"
    APP_URL   = "https://activity.dosomething.org"
  }

  buildpacks = [
    "heroku/nodejs",
    "heroku/php",
  ]

  acm = true
}

resource "heroku_formation" "rogue" {
  app      = "${heroku_app.rogue.name}"
  type     = "web"
  size     = "Standard-2X"
  quantity = 2
}

resource "heroku_formation" "rogue-queue" {
  app      = "${heroku_app.rogue.name}"
  type     = "queue"
  size     = "Standard-1X"
  quantity = 2
}

resource "heroku_domain" "rogue" {
  app      = "${heroku_app.rogue.name}"
  hostname = "activity.dosomething.org"
}

resource "heroku_drain" "rogue" {
  app = "${heroku_app.rogue.name}"
  url = "syslog+tls://${var.papertrail_destination}"
}

resource "heroku_pipeline_coupling" "rogue" {
  app      = "${heroku_app.rogue.name}"
  pipeline = "${var.rogue_pipeline}"
  stage    = "production"
}

# ----------------------------

output "name" {
  value = "${heroku_app.rogue.name}"
}

output "domain" {
  value = "${heroku_domain.rogue.hostname}"
}

output "backend" {
  value = "${heroku_app.rogue.heroku_hostname}"
}

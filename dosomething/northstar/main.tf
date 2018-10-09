variable "northstar_pipeline" {}
variable "papertrail_destination" {}

resource "heroku_app" "northstar" {
  name   = "dosomething-northstar"
  region = "us"

  organization {
    name = "dosomething"
  }

  config_vars {
    APP_ENV   = "production"
    APP_DEBUG = "false"
    APP_LOG   = "errorlog"
    APP_URL   = "https://identity.dosomething.org"
  }

  buildpacks = [
    "heroku/nodejs",
    "heroku/php",
  ]

  acm = true
}

# @TODO: Terraform doesn't support auto-scaling here. Re-add
# if support is added in a future Heroku provider update.
# resource "heroku_formation" "northstar" {
#   app      = "${heroku_app.northstar.name}"
#   type     = "web"
#   size     = "Performance-M"
#   quantity = 1
# }

resource "heroku_formation" "northstar-queue" {
  app      = "${heroku_app.northstar.name}"
  type     = "queue"
  size     = "Standard-1X"
  quantity = 1
}

resource "heroku_domain" "northstar" {
  app      = "${heroku_app.northstar.name}"
  hostname = "identity.dosomething.org"
}

resource "heroku_drain" "northstar" {
  app = "${heroku_app.northstar.name}"
  url = "syslog+tls://${var.papertrail_destination}"
}

resource "heroku_pipeline_coupling" "northstar" {
  app      = "${heroku_app.northstar.name}"
  pipeline = "${var.northstar_pipeline}"
  stage    = "production"
}

# ----------------------------

output "name" {
  value = "${heroku_app.northstar.name}"
}

output "domain" {
  value = "${heroku_domain.northstar.hostname}"
}

output "backend" {
  value = "${heroku_app.northstar.heroku_hostname}"
}

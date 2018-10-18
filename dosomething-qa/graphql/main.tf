variable "graphql_pipeline" {}
variable "papertrail_destination" {}

resource "heroku_app" "graphql-qa" {
  name   = "dosomething-graphql-qa"
  region = "us"

  organization {
    name = "dosomething"
  }

  config_vars {
    APP_ENV              = "qa"
    QUERY_ENV            = "qa"
    APP_URL              = "https://graphql-qa.dosomething.org"
    GRAPHQL_ENDPOINT_URL = "https://graphql-qa.dosomething.org/graphql"
  }

  buildpacks = [
    "heroku/nodejs",
  ]

  acm = true
}

resource "heroku_formation" "web" {
  app      = "${heroku_app.graphql-qa.name}"
  type     = "web"
  size     = "hobby"
  quantity = 1
}

resource "heroku_addon" "redis" {
  app  = "${heroku_app.graphql-qa.name}"
  plan = "heroku-redis:hobby-dev"
}

resource "heroku_domain" "graphql-qa" {
  app      = "${heroku_app.graphql-qa.name}"
  hostname = "graphql-qa.dosomething.org"
}

resource "heroku_drain" "papertrail" {
  app = "${heroku_app.graphql-qa.name}"
  url = "syslog+tls://${var.papertrail_destination}"
}

resource "heroku_pipeline_coupling" "graphql-qa" {
  app      = "${heroku_app.graphql-qa.name}"
  pipeline = "${var.graphql_pipeline}"
  stage    = "staging"
}

output "name" {
  value = "${heroku_app.graphql-qa.name}"
}

output "domain" {
  value = "${heroku_domain.graphql-qa.hostname}"
}

output "backend" {
  value = "${heroku_app.graphql-qa.heroku_hostname}"
}

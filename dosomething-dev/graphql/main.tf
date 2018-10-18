variable "graphql_pipeline" {}
variable "papertrail_destination" {}

resource "heroku_app" "graphql-dev" {
  name   = "dosomething-graphql-dev"
  region = "us"

  organization {
    name = "dosomething"
  }

  config_vars {
    APP_ENV              = "dev"
    QUERY_ENV            = "dev"
    APP_URL              = "https://graphql-dev.dosomething.org"
    GRAPHQL_ENDPOINT_URL = "https://graphql-dev.dosomething.org/graphql"
  }

  buildpacks = [
    "heroku/nodejs",
  ]

  acm = true
}

resource "heroku_formation" "web" {
  app      = "${heroku_app.graphql-dev.name}"
  type     = "web"
  size     = "hobby"
  quantity = 1
}

resource "heroku_addon" "redis" {
  app  = "${heroku_app.graphql-dev.name}"
  plan = "heroku-redis:hobby-dev"
}

resource "heroku_domain" "graphql-dev" {
  app      = "${heroku_app.graphql-dev.name}"
  hostname = "graphql-dev.dosomething.org"
}

resource "heroku_drain" "papertrail" {
  app = "${heroku_app.graphql-dev.name}"
  url = "syslog+tls://${var.papertrail_destination}"
}

resource "heroku_pipeline_coupling" "graphql-dev" {
  app      = "${heroku_app.graphql-dev.name}"
  pipeline = "${var.graphql_pipeline}"
  stage    = "development"
}

output "name" {
  value = "${heroku_app.graphql-dev.name}"
}

output "domain" {
  value = "${heroku_domain.graphql-dev.hostname}"
}

output "backend" {
  value = "${heroku_app.graphql-dev.heroku_hostname}"
}

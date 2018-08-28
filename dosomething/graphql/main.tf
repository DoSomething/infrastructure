variable "graphql_pipeline" {}
variable "papertrail_destination" {}

resource "heroku_app" "graphql" {
  name   = "dosomething-graphql"
  region = "us"

  organization {
    name = "dosomething"
  }

  config_vars {
    APP_ENV              = "production"
    QUERY_ENV            = "production"
    APP_URL              = "https://graphql.dosomething.org"
    GRAPHQL_ENDPOINT_URL = "https://graphql.dosomething.org/graphql"
  }

  buildpacks = [
    "heroku/nodejs",
  ]

  acm = true
}

resource "heroku_formation" "graphql" {
  app      = "${heroku_app.graphql.name}"
  type     = "web"
  size     = "standard-1x"
  quantity = 1
}

resource "heroku_addon" "graphql-redis" {
  app  = "${heroku_app.graphql.name}"
  plan = "heroku-redis:hobby-dev"
}

resource "heroku_domain" "graphql" {
  app      = "${heroku_app.graphql.name}"
  hostname = "graphql.dosomething.org"
}

resource "heroku_drain" "graphql" {
  app = "${heroku_app.graphql.name}"
  url = "syslog+tls://${var.papertrail_destination}"
}

resource "heroku_pipeline_coupling" "graphql" {
  app      = "${heroku_app.graphql.name}"
  pipeline = "${var.graphql_pipeline}"
  stage    = "production"
}

# ----------------------------------------------------

output "name" {
  value = "${heroku_app.graphql.name}"
}

output "domain" {
  value = "${heroku_domain.graphql.hostname}"
}

output "backend" {
  value = "${heroku_app.graphql.heroku_hostname}"
}

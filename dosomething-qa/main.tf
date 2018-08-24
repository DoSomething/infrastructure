variable "papertrail_qa_destination" {}

resource "heroku_pipeline" "graphql" {
  name = "graphql"
}

resource "heroku_app" "graphql-dev" {
  name   = "dosomething-graphql-dev"
  region = "us"

  organization {
    name = "dosomething"
  }

  config_vars {
    APP_ENV = "dev"
    QUERY_ENV = "dev"
    APP_URL = "https://graphql-dev.dosomething.org"
    GRAPHQL_ENDPOINT_URL = "https://graphql-dev.dosomething.org/graphql"
  }

  buildpacks = [
    "heroku/nodejs"
  ]

  acm = true
}

resource "heroku_formation" "graphql-dev" {
  app  = "${heroku_app.graphql-dev.name}"
  type = "web"
  size = "hobby"
  quantity = 1
}

resource "heroku_addon" "graphql-dev-redis" {
  app  = "${heroku_app.graphql-dev.name}"
  plan = "heroku-redis:hobby-dev"
}

resource "heroku_domain" "default" {
  app      = "${heroku_app.graphql-dev.name}"
  hostname = "graphql-dev.dosomething.org"
}

resource "heroku_drain" "default" {
  app = "${heroku_app.graphql-dev.name}"
  url = "syslog://${var.papertrail_qa_destination}"
}

resource "heroku_pipeline_coupling" "staging" {
  app      = "${heroku_app.graphql-dev.name}"
  pipeline = "${heroku_pipeline.graphql.id}"
  stage    = "development"
}

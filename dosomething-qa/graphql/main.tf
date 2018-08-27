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

resource "heroku_formation" "graphql-dev" {
  app      = "${heroku_app.graphql-dev.name}"
  type     = "web"
  size     = "hobby"
  quantity = 1
}

resource "heroku_addon" "graphql-dev-redis" {
  app  = "${heroku_app.graphql-dev.name}"
  plan = "heroku-redis:hobby-dev"
}

resource "heroku_domain" "graphql-dev" {
  app      = "${heroku_app.graphql-dev.name}"
  hostname = "graphql-dev.dosomething.org"
}

resource "heroku_drain" "graphql-dev" {
  app = "${heroku_app.graphql-dev.name}"
  url = "syslog+tls://${var.papertrail_destination}"
}

resource "heroku_pipeline_coupling" "graphql-dev" {
  app      = "${heroku_app.graphql-dev.name}"
  pipeline = "${var.graphql_pipeline}"
  stage    = "development"
}

# ----------------------------

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

resource "heroku_formation" "graphql-qa" {
  app      = "${heroku_app.graphql-qa.name}"
  type     = "web"
  size     = "hobby"
  quantity = 1
}

resource "heroku_addon" "graphql-qa-redis" {
  app  = "${heroku_app.graphql-qa.name}"
  plan = "heroku-redis:hobby-dev"
}

resource "heroku_domain" "graphql-qa" {
  app      = "${heroku_app.graphql-qa.name}"
  hostname = "graphql-qa.dosomething.org"
}

resource "heroku_drain" "graphql-qa" {
  app = "${heroku_app.graphql-qa.name}"
  url = "syslog+tls://${var.papertrail_destination}"
}

resource "heroku_pipeline_coupling" "graphql-qa" {
  app      = "${heroku_app.graphql-qa.name}"
  pipeline = "${var.graphql_pipeline}"
  stage    = "staging"
}

# ----------------------------

output "name_dev" {
  value = "${heroku_app.graphql-dev.name}"
}

output "domain_dev" {
  value = "${heroku_domain.graphql-dev.hostname}"
}

output "backend_dev" {
  value = "${heroku_app.graphql-dev.heroku_hostname}"
}

output "name_qa" {
  value = "${heroku_app.graphql-qa.name}"
}

output "domain_qa" {
  value = "${heroku_domain.graphql-qa.hostname}"
}

output "backend_qa" {
  value = "${heroku_app.graphql-qa.heroku_hostname}"
}

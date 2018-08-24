variable "papertrail_qa_destination" {}

resource "fastly_service_v1" "dosomething-qa" {
  name = "Terraform: DoSomething (QA)"
  force_destroy = true

  domain {
    name = "${heroku_domain.graphql-dev.hostname}"
  }

  domain {
    name = "${heroku_domain.graphql-qa.hostname}"
  }

  condition {
    type = "request"
    name = "backend-graphql-dev"
    statement = "req.http.host == \"${heroku_domain.graphql-dev.hostname}\""
  }

  condition {
    type = "request"
    name = "backend-graphql-qa"
    statement = "req.http.host == \"${heroku_domain.graphql-qa.hostname}\""
  }

  backend {
    address = "${heroku_app.graphql-dev.heroku_hostname}"
    name = "${heroku_app.graphql-dev.name}"
    request_condition = "backend-graphql-dev"
    port = 443
  }
  
  backend {
    address = "${heroku_app.graphql-qa.heroku_hostname}"
    name = "${heroku_app.graphql-qa.name}"
    request_condition = "backend-graphql-qa"
    port = 443
  }
}

# ----------------------------

resource "heroku_pipeline" "graphql" {
  name = "graphql"
}

# ----------------------------

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

resource "heroku_domain" "graphql-dev" {
  app      = "${heroku_app.graphql-dev.name}"
  hostname = "graphql-dev.dosomething.org"
}

resource "heroku_drain" "graphql-dev" {
  app = "${heroku_app.graphql-dev.name}"
  url = "syslog+tls://${var.papertrail_qa_destination}"
}

resource "heroku_pipeline_coupling" "graphql-dev" {
  app      = "${heroku_app.graphql-dev.name}"
  pipeline = "${heroku_pipeline.graphql.id}"
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
    APP_ENV = "qa"
    QUERY_ENV = "qa"
    APP_URL = "https://graphql-qa.dosomething.org"
    GRAPHQL_ENDPOINT_URL = "https://graphql-qa.dosomething.org/graphql"
  }

  buildpacks = [
    "heroku/nodejs"
  ]

  acm = true
}

resource "heroku_formation" "graphql-qa" {
  app  = "${heroku_app.graphql-qa.name}"
  type = "web"
  size = "hobby"
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
  url = "syslog+tls://${var.papertrail_qa_destination}"
}

resource "heroku_pipeline_coupling" "graphql-qa" {
  app      = "${heroku_app.graphql-qa.name}"
  pipeline = "${heroku_pipeline.graphql.id}"
  stage    = "staging"
}

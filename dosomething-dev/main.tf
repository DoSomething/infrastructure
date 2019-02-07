variable "graphql_pipeline" {}
variable "northstar_pipeline" {}
variable "phoenix_pipeline" {}
variable "rogue_pipeline" {}
variable "papertrail_destination" {}
variable "papertrail_destination_fastly" {}

module "fastly-frontend" {
  source = "fastly-frontend"

  phoenix_name    = "${module.phoenix.name}"
  phoenix_backend = "${module.phoenix.backend}"

  ashes_backend = "${module.ashes.backend}"

  papertrail_destination = "${var.papertrail_destination_fastly}"
}

module "fastly-backend" {
  source = "fastly-backend"

  graphql_name    = "${module.graphql.name}"
  graphql_domain  = "${module.graphql.domain}"
  graphql_backend = "${module.graphql.backend}"

  northstar_name    = "${module.northstar.name}"
  northstar_domain  = "${module.northstar.domain}"
  northstar_backend = "${module.northstar.backend}"

  phoenix_name    = "${module.phoenix.name}"
  phoenix_domain  = "${module.phoenix.domain}"
  phoenix_backend = "${module.phoenix.backend}"

  rogue_name    = "${module.rogue.name}"
  rogue_domain  = "${module.rogue.domain}"
  rogue_backend = "${module.rogue.backend}"

  papertrail_destination = "${var.papertrail_destination_fastly}"
}

module "graphql" {
  source = "../applications/graphql"

  environment            = "development"
  name                   = "dosomething-graphql-dev"
  domain                 = "graphql-dev.dosomething.org"
  pipeline               = "${var.graphql_pipeline}"
  papertrail_destination = "${var.papertrail_destination}"
}

module "graphql_lambda" {
  source = "../applications/graphql-lambda"

  environment = "development"
  name        = "dosomething-graphql-dev"
  domain      = "graphql-lambda-dev.dosomething.org"
  logger      = "${module.papertrail.arn}"
}

module "northstar" {
  source = "../applications/northstar"

  environment            = "development"
  name                   = "dosomething-northstar-dev"
  domain                 = "identity-dev.dosomething.org"
  pipeline               = "${var.northstar_pipeline}"
  papertrail_destination = "${var.papertrail_destination}"
}

module "phoenix" {
  source = "../applications/phoenix"

  environment            = "development"
  name                   = "dosomething-phoenix-dev"
  domain                 = "www-dev.dosomething.org"       # TODO: Just 'dev.dosomething.org'?
  pipeline               = "${var.phoenix_pipeline}"
  papertrail_destination = "${var.papertrail_destination}"
}

module "rogue" {
  source = "../applications/rogue"

  environment            = "development"
  name                   = "dosomething-rogue-dev"
  domain                 = "activity-dev.dosomething.org"
  pipeline               = "${var.rogue_pipeline}"
  papertrail_destination = "${var.papertrail_destination}"
}

module "papertrail" {
  source = "../applications/papertrail"

  environment            = "development"
  name                   = "papertrail-dev"
  papertrail_destination = "${var.papertrail_destination}"
}

module "example" {
  source = "../applications/hello-serverless"

  logger = "${module.papertrail.arn}"
}

module "ashes" {
  source = "ashes"
}

variable "northstar_pipeline" {}
variable "phoenix_pipeline" {}
variable "rogue_pipeline" {}
variable "papertrail_destination" {}
variable "papertrail_destination_fastly" {}

module "chompy" {
  source = "../applications/chompy"

  name = "dosomething-chompy-qa"
}

module "fastly-frontend" {
  source = "fastly-frontend"

  phoenix_name    = "${module.phoenix.name}"
  phoenix_backend = "${module.phoenix.backend}"

  papertrail_destination = "${var.papertrail_destination_fastly}"
}

module "fastly-backend" {
  source = "fastly-backend"

  northstar_name    = "${module.northstar.name}"
  northstar_domain  = "${module.northstar.domain}"
  northstar_backend = "${module.northstar.backend}"

  rogue_name    = "${module.rogue.name}"
  rogue_domain  = "${module.rogue.domain}"
  rogue_backend = "${module.rogue.backend}"

  papertrail_destination = "${var.papertrail_destination_fastly}"
}

module "graphql" {
  source = "../applications/graphql"

  environment = "qa"
  name        = "dosomething-graphql-qa"
  domain      = "graphql-qa.dosomething.org"
  logger      = "${module.papertrail.arn}"
}

module "northstar" {
  source = "../applications/northstar"

  environment            = "qa"
  name                   = "dosomething-northstar-qa"
  domain                 = "identity-qa.dosomething.org"
  pipeline               = "${var.northstar_pipeline}"
  papertrail_destination = "${var.papertrail_destination}"
}

module "phoenix" {
  source = "../applications/phoenix"

  environment            = "qa"
  name                   = "dosomething-phoenix-qa"
  domain                 = "qa.dosomething.org"
  pipeline               = "${var.phoenix_pipeline}"
  papertrail_destination = "${var.papertrail_destination}"
}

module "rogue" {
  source = "../applications/rogue"

  environment            = "qa"
  name                   = "dosomething-rogue-qa"
  domain                 = "activity-qa.dosomething.org"
  pipeline               = "${var.rogue_pipeline}"
  papertrail_destination = "${var.papertrail_destination}"
}

module "papertrail" {
  source = "../applications/papertrail"

  environment            = "qa"
  name                   = "papertrail-qa"
  papertrail_destination = "${var.papertrail_destination}"
}

module "ashes" {
  source = "ashes"
}

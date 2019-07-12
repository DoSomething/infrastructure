variable "northstar_pipeline" {}
variable "phoenix_pipeline" {}
variable "rogue_pipeline" {}
variable "papertrail_destination" {}
variable "papertrail_destination_fastly" {}

locals {
  papertrail_log_format = "%t '%r' status=%>s app=%{X-Application-Name}o cache=\"%{X-Cache}o\" country=%{X-Fastly-Country-Code}o ip=\"%a\" user-agent=\"%{User-Agent}i\" service=%{time.elapsed.msec}Vms"
}

module "fastly-frontend" {
  source = "./fastly-frontend"

  phoenix_name    = "${module.phoenix.name}"
  phoenix_backend = "${module.phoenix.backend}"

  papertrail_destination = "${var.papertrail_destination_fastly}"
  papertrail_log_format  = "${local.papertrail_log_format}"
}

module "fastly-backend" {
  source = "./fastly-backend"

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
  papertrail_log_format  = "${local.papertrail_log_format}"
}

module "graphql" {
  source = "../applications/graphql"

  environment = "development"
  name        = "dosomething-graphql-dev"
  domain      = "graphql-dev.dosomething.org"
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
  domain                 = "dev.dosomething.org"
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
  source = "./ashes"
}

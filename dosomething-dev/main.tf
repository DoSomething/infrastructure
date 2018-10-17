variable "graphql_pipeline" {}
variable "northstar_pipeline" {}
variable "phoenix_pipeline" {}
variable "rogue_pipeline" {}
variable "papertrail_destination" {}
variable "papertrail_destination_fastly_dev" {}

module "fastly-frontend" {
  source = "fastly-frontend"

  ashes_backend_dev = "${module.ashes.backend_dev}"

  papertrail_destination = "${var.papertrail_destination_fastly_dev}"
}

module "fastly-backend" {
  source = "fastly-backend"

  graphql_name_dev    = "${module.graphql.name_dev}"
  graphql_domain_dev  = "${module.graphql.domain_dev}"
  graphql_backend_dev = "${module.graphql.backend_dev}"

  northstar_name_dev    = "${module.northstar.name_dev}"
  northstar_domain_dev  = "${module.northstar.domain_dev}"
  northstar_backend_dev = "${module.northstar.backend_dev}"

  rogue_name_dev    = "${module.rogue.name_dev}"
  rogue_domain_dev  = "${module.rogue.domain_dev}"
  rogue_backend_dev = "${module.rogue.backend_dev}"

  papertrail_destination_fastly_dev = "${var.papertrail_destination_fastly_dev}"
}

module "graphql" {
  source = "graphql"

  graphql_pipeline       = "${var.graphql_pipeline}"
  papertrail_destination = "${var.papertrail_destination}"
}

module "northstar" {
  source = "northstar"

  northstar_pipeline     = "${var.northstar_pipeline}"
  papertrail_destination = "${var.papertrail_destination}"
}

module "phoenix" {
  source = "phoenix"

  phoenix_pipeline       = "${var.phoenix_pipeline}"
  papertrail_destination = "${var.papertrail_destination}"
}

module "rogue" {
  source = "rogue"

  rogue_pipeline         = "${var.rogue_pipeline}"
  papertrail_destination = "${var.papertrail_destination}"
}

module "ashes" {
  source = "ashes"
}

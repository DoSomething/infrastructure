variable "graphql_pipeline" {}
variable "northstar_pipeline" {}
variable "rogue_pipeline" {}
variable "papertrail_destination" {}
variable "papertrail_destination_fastly_dev" {}
variable "papertrail_destination_fastly_qa" {}

module "fastly-frontend" {
  source = "fastly-frontend"

  ashes_backend_dev = "${module.ashes.backend_dev}"
  ashes_backend_qa  = "${module.ashes.backend_qa}"

  # papertrail_destination_fastly_dev = "${var.papertrail_destination_fastly_dev}"
  # papertrail_destination_fastly_qa  = "${var.papertrail_destination_fastly_qa}"
}

module "fastly-backend" {
  source = "fastly-backend"

  graphql_name_dev    = "${module.graphql.name_dev}"
  graphql_domain_dev  = "${module.graphql.domain_dev}"
  graphql_backend_dev = "${module.graphql.backend_dev}"
  graphql_name_qa     = "${module.graphql.name_qa}"
  graphql_domain_qa   = "${module.graphql.domain_qa}"
  graphql_backend_qa  = "${module.graphql.backend_qa}"

  northstar_name_dev    = "${module.northstar.name_dev}"
  northstar_domain_dev  = "${module.northstar.domain_dev}"
  northstar_backend_dev = "${module.northstar.backend_dev}"
  northstar_name_qa     = "${module.northstar.name_qa}"
  northstar_domain_qa   = "${module.northstar.domain_qa}"
  northstar_backend_qa  = "${module.northstar.backend_qa}"

  rogue_name_dev    = "${module.rogue.name_dev}"
  rogue_domain_dev  = "${module.rogue.domain_dev}"
  rogue_backend_dev = "${module.rogue.backend_dev}"
  rogue_name_qa     = "${module.rogue.name_qa}"
  rogue_domain_qa   = "${module.rogue.domain_qa}"
  rogue_backend_qa  = "${module.rogue.backend_qa}"

  ashes_backend_dev = "${module.ashes.backend_dev}"

  papertrail_destination            = "${var.papertrail_destination}"
  papertrail_destination_fastly_dev = "${var.papertrail_destination_fastly_dev}"
  papertrail_destination_fastly_qa  = "${var.papertrail_destination_fastly_qa}"
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

module "rogue" {
  source = "rogue"

  rogue_pipeline         = "${var.rogue_pipeline}"
  papertrail_destination = "${var.papertrail_destination}"
}

module "ashes" {
  source = "ashes"
}

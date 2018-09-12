variable "graphql_pipeline" {}
variable "northstar_pipeline" {}
variable "rogue_pipeline" {}
variable "papertrail_destination" {}

module "fastly" {
  source = "fastly"

  graphql_name_dev      = "${module.graphql.name_dev}"
  graphql_domain_dev    = "${module.graphql.domain_dev}"
  graphql_backend_dev   = "${module.graphql.backend_dev}"
  graphql_name_qa       = "${module.graphql.name_qa}"
  graphql_domain_qa     = "${module.graphql.domain_qa}"
  graphql_backend_qa    = "${module.graphql.backend_qa}"
  ashes_backend_staging = "${module.ashes.backend_staging}"
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

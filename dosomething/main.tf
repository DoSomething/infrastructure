variable "graphql_pipeline" {}
variable "northstar_pipeline" {}
variable "papertrail_destination" {}
variable "papertrail_destination_fastly" {}

module "fastly" {
  source = "fastly"

  graphql_name    = "${module.graphql.name}"
  graphql_domain  = "${module.graphql.domain}"
  graphql_backend = "${module.graphql.backend}"

  northstar_name    = "${module.northstar.name}"
  northstar_domain  = "${module.northstar.domain}"
  northstar_backend = "${module.northstar.backend}"

  papertrail_destination = "${var.papertrail_destination_fastly}"
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

variable "northstar_pipeline" {}
variable "phoenix_pipeline" {}
variable "rogue_pipeline" {}
variable "papertrail_destination" {}
variable "papertrail_destination_fastly" {}

locals {
  papertrail_log_format = "%t '%r' status=%>s app=%%{X-Application-Name}o cache=\"%%{X-Cache}o\" country=%%{X-Fastly-Country-Code}o ip=\"%a\" user-agent=\"%%{User-Agent}i\" service=%%{time.elapsed.msec}Vms"
}

module "chompy" {
  source = "../applications/chompy"

  name = "dosomething-chompy-qa"
}

module "fastly-frontend" {
  source = "./fastly-frontend"

  phoenix_name    = module.phoenix.name
  phoenix_backend = module.phoenix.backend

  papertrail_destination = var.papertrail_destination_fastly
  papertrail_log_format  = local.papertrail_log_format
}

module "fastly-backend" {
  source = "./fastly-backend"

  northstar_name    = module.northstar.name
  northstar_domain  = module.northstar.domain
  northstar_backend = module.northstar.backend

  rogue_name    = "dosomething-rogue-qa"
  rogue_domain  = "activity-qa.dosomething.org"
  rogue_backend = "dosomething-rogue-qa.herokuapp.com"

  papertrail_destination = var.papertrail_destination_fastly
  papertrail_log_format  = local.papertrail_log_format
}

module "graphql" {
  source = "../applications/graphql"

  environment = "qa"
  name        = "dosomething-graphql-qa"
  domain      = "graphql-qa.dosomething.org"
  logger      = module.papertrail
}

module "northstar" {
  source = "../applications/northstar"

  environment            = "qa"
  name                   = "dosomething-northstar-qa"
  domain                 = "identity-qa.dosomething.org"
  pipeline               = var.northstar_pipeline
  papertrail_destination = var.papertrail_destination
}

module "phoenix" {
  source = "../applications/phoenix"

  environment            = "qa"
  name                   = "dosomething-phoenix-qa"
  domain                 = "qa.dosomething.org"
  pipeline               = var.phoenix_pipeline
  papertrail_destination = var.papertrail_destination
}

module "rogue" {
  source = "../applications/rogue"

  environment            = "qa"
  name                   = "dosomething-rogue-qa"
  domain                 = "activity-qa.dosomething.org"
  pipeline               = var.rogue_pipeline
  northstar_url          = "https://identity-qa.dosomething.org"
  graphql_url            = "https://graphql-qa.dosomething.org/graphql"
  blink_url              = "https://blink-staging.dosomething.org/api/"
  papertrail_destination = var.papertrail_destination
}

module "papertrail" {
  source = "../applications/papertrail"

  environment            = "qa"
  name                   = "papertrail-qa"
  papertrail_destination = var.papertrail_destination
}

module "ashes" {
  source = "./ashes"
}


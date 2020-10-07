variable "fastly_api_key" {}
variable "heroku_email" {}
variable "heroku_api_key" {}
variable "papertrail_destination" {}
variable "papertrail_destination_fastly" {}
variable "northstar_pipeline" {}
variable "phoenix_pipeline" {}
variable "rogue_pipeline" {}

terraform {
  backend "remote" {
    organization = "dosomething"

    workspaces {
      prefix = "dosomething-"
    }
  }
}

provider "fastly" {
  version = "0.9.0"
  api_key = var.fastly_api_key
}

provider "heroku" {
  version = "2.2.0"
  email   = var.heroku_email
  api_key = var.heroku_api_key
}

provider "aws" {
  version = "2.48.0"
  region  = "us-east-1"
  profile = "terraform"
}

provider "aws" {
  alias   = "west"
  region  = "us-west-1"
  profile = "terraform"
}

provider "template" {
  version = "~> 2.1"
}

provider "random" {
  version = "~> 2.0"
}

provider "null" {
  version = "~> 2.1"
}

module "bertly" {
  source = "../applications/bertly"

  environment   = "qa"
  name          = "dosomething-bertly-qa"
  domain        = "qa.dosome.click"
  certificate   = "*.dosome.click"
  northstar_url = "https://identity-qa.dosomething.org"
  logger        = module.papertrail
}

module "chompy" {
  source = "../applications/chompy"

  name = "dosomething-chompy-qa"
}

module "fastly-frontend" {
  source = "../components/fastly_frontend"
  name   = "Terraform: Frontend (QA)"

  environment            = "qa"
  application            = module.phoenix
  papertrail_destination = var.papertrail_destination_fastly
}

module "fastly-backend" {
  source = "../components/fastly_backends"
  name   = "Terraform: Backends (QA)"

  applications = [
    module.northstar,
    module.rogue,
  ]

  papertrail_destination = var.papertrail_destination_fastly
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

  environment = "qa"
  name        = "dosomething-northstar-qa"
  domain      = "identity-qa.dosomething.org"
  pipeline    = var.northstar_pipeline

  papertrail_destination = var.papertrail_destination
}

module "phoenix" {
  source = "../applications/phoenix"

  environment = "qa"
  name        = "dosomething-phoenix-qa"
  domain      = "qa.dosomething.org"
  pipeline    = var.phoenix_pipeline

  papertrail_destination = var.papertrail_destination
}

module "rogue" {
  source = "../applications/rogue"

  environment   = "qa"
  name          = "dosomething-rogue-qa"
  domain        = "activity-qa.dosomething.org"
  pipeline      = var.rogue_pipeline
  northstar_url = "https://identity-qa.dosomething.org"
  gambit_url    = "https://gambit-conversations-staging.herokuapp.com"
  graphql_url   = "https://graphql-qa.dosomething.org/graphql"
  blink_url     = "https://blink-staging.dosomething.org/api/"

  papertrail_destination = var.papertrail_destination
}

module "papertrail" {
  source = "../applications/papertrail"

  environment = "qa"
  name        = "papertrail-qa"

  papertrail_destination = var.papertrail_destination
}

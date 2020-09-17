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

locals {
  papertrail_log_format = "%t '%r' status=%>s app=%%{X-Application-Name}o cache=\"%%{X-Cache}o\" country=%%{X-Fastly-Country-Code}o ip=\"%a\" user-agent=\"%%{User-Agent}i\" service=%%{time.elapsed.msec}Vms"
}

module "bertly" {
  source = "../applications/bertly"

  environment   = "development"
  name          = "dosomething-bertly-dev"
  domain        = "dev.dosome.click"
  certificate   = "*.dosome.click"
  northstar_url = "https://identity-dev.dosomething.org"
  logger        = module.papertrail
}

module "fastly-frontend" {
  source = "./fastly-frontend"

  phoenix_name    = module.phoenix.name
  phoenix_backend = module.phoenix.backend

  papertrail_destination = var.papertrail_destination_fastly
  papertrail_log_format  = local.papertrail_log_format
}

module "fastly-backend" {
  source = "../components/fastly_backends"
  name   = "Fastly: Backends (Development)"

  backends = [
    module.northstar,
    module.rogue,
  ]

  papertrail_destination = var.papertrail_destination_fastly
}

module "graphql" {
  source = "../applications/graphql"

  environment = "development"
  name        = "dosomething-graphql-dev"
  domain      = "graphql-dev.dosomething.org"
  logger      = module.papertrail
}

module "northstar" {
  source = "../applications/northstar"

  environment            = "development"
  name                   = "dosomething-northstar-dev"
  domain                 = "identity-dev.dosomething.org"
  pipeline               = var.northstar_pipeline
  papertrail_destination = var.papertrail_destination
}

module "phoenix" {
  source = "../applications/phoenix"

  environment            = "development"
  name                   = "dosomething-phoenix-dev"
  domain                 = "dev.dosomething.org"
  pipeline               = var.phoenix_pipeline
  papertrail_destination = var.papertrail_destination
}

module "rogue" {
  source = "../applications/rogue"

  environment            = "development"
  name                   = "dosomething-rogue-dev"
  domain                 = "activity-dev.dosomething.org"
  pipeline               = var.rogue_pipeline
  northstar_url          = "https://identity-dev.dosomething.org"
  graphql_url            = "https://graphql-dev.dosomething.org/graphql"
  blink_url              = "https://blink-staging.dosomething.org/api/"
  papertrail_destination = var.papertrail_destination
}

module "papertrail" {
  source = "../applications/papertrail"

  environment            = "development"
  name                   = "papertrail-dev"
  papertrail_destination = var.papertrail_destination
}

module "example" {
  source = "../applications/hello-serverless"

  logger = module.papertrail
}


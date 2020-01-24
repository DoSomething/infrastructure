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
  version = "2.30.0"
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

module "assets" {
  source = "../applications/static"

  domain = "assets.dosomething.org"
}

module "chompy" {
  source = "../applications/chompy"

  name = "dosomething-chompy"
}

module "fastly-frontend" {
  source = "./fastly-frontend"

  assets_domain  = module.assets.domain
  assets_backend = module.assets.backend

  phoenix_name    = module.phoenix.name
  phoenix_backend = module.phoenix.backend

  papertrail_destination = var.papertrail_destination_fastly
  papertrail_log_format  = local.papertrail_log_format
}

module "fastly-backend" {
  source = "./fastly-backend"

  phoenix_preview_name    = module.phoenix_preview.name
  phoenix_preview_domain  = module.phoenix_preview.domain
  phoenix_preview_backend = module.phoenix_preview.backend

  northstar_name    = module.northstar.name
  northstar_domain  = module.northstar.domain
  northstar_backend = module.northstar.backend

  rogue_name    = module.rogue.name
  rogue_domain  = module.rogue.domain
  rogue_backend = module.rogue.backend

  papertrail_destination = var.papertrail_destination_fastly
  papertrail_log_format  = local.papertrail_log_format
}

module "graphql" {
  source = "../applications/graphql"

  environment = "production"
  name        = "dosomething-graphql"
  domain      = "graphql.dosomething.org"
  logger      = module.papertrail
}

module "northstar" {
  source = "../applications/northstar"

  environment            = "production"
  name                   = "dosomething-northstar"
  domain                 = "identity.dosomething.org"
  pipeline               = var.northstar_pipeline
  papertrail_destination = var.papertrail_destination
}

module "phoenix" {
  source = "../applications/phoenix"

  environment            = "production"
  name                   = "dosomething-phoenix"
  domain                 = "www.dosomething.org"
  pipeline               = var.phoenix_pipeline
  papertrail_destination = var.papertrail_destination
}

module "phoenix_preview" {
  source = "../applications/phoenix"

  environment            = "production"
  name                   = "dosomething-phoenix-preview"
  domain                 = "preview.dosomething.org"
  web_size               = "Standard-1x"
  pipeline               = var.phoenix_pipeline
  papertrail_destination = var.papertrail_destination

  use_contentful_preview_api = true
}

module "rogue_backup" {
  source = "../components/s3_bucket"
  providers = {
    aws = "aws.west"
  }

  name       = "dosomething-rogue-backup"
  acl        = "private"
  versioning = true
  archived   = true
}

module "rogue" {
  source = "../applications/rogue"

  environment            = "production"
  name                   = "dosomething-rogue"
  domain                 = "activity.dosomething.org"
  pipeline               = var.rogue_pipeline
  northstar_url          = "https://identity.dosomething.org"
  graphql_url            = "https://graphql.dosomething.org/graphql"
  blink_url              = "https://blink.dosomething.org/api/"
  papertrail_destination = var.papertrail_destination
  backup_storage_bucket  = module.rogue_backup.bucket
}

module "ashes" {
  source = "./ashes"
}

# We use this Lambda function to forward logs to Papertrail
# for production applications & our Quasar warehouse.
module "papertrail" {
  source = "../applications/papertrail"

  environment            = "production"
  name                   = "papertrail"
  papertrail_destination = var.papertrail_destination
}

output "papertrail_forwarder" {
  value = module.forwarder
}

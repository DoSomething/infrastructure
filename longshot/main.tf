variable "papertrail_prod_destination" {}
variable "papertrail_qa_destination" {}

terraform {
  backend "remote" {
    organization = "dosomething"

    workspaces {
      name = "longshot"
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

provider "template" {
  version = "~> 2.1"
}

provider "random" {
  version = "~> 2.0"
}

provider "null" {
  version = "~> 2.1"
}

resource "heroku_pipeline" "longshot" {
  name = "longshot"
}

module "longshot-qa" {
  source = "../applications/longshot"

  name        = "longshot-qa"
  domain      = "longshot-qa.dosomething.org"
  pipeline    = "${heroku_pipeline.longshot.id}"
  environment = "qa"

  email_name    = "Longshot QA"
  email_address = "devops@dosomething.org"

  papertrail_destination = "${var.papertrail_qa_destination}"
}

module "longshot-footlocker" {
  source = "../applications/longshot"

  name        = "longshot-footlocker"
  domain      = "footlockerscholarathletes.com"
  pipeline    = "${heroku_pipeline.longshot.id}"
  environment = "production"

  email_name    = "Foot Locker Scholar Athletes"
  email_address = "footlocker@tmiagency.org"

  papertrail_destination = "${var.papertrail_prod_destination}"
}

module "longshot-footlocker-internal" {
  source = "../applications/longshot"

  name        = "longshot-footlocker-internal"
  domain      = "www.flscholarship.com"
  pipeline    = "${heroku_pipeline.longshot.id}"
  environment = "production"

  email_name    = "Foot Locker Scholar Athletes"
  email_address = "footlocker@tmiagency.org"

  papertrail_destination = "${var.papertrail_prod_destination}"
  with_newrelic          = false
}

# Attach base domain for FLScholarship.com as well.
# TODO: Is there a better way to handle ANAMEs?
resource "heroku_domain" "flscholarship_base_domain" {
  app      = "${module.longshot-footlocker-internal.name}"
  hostname = "flscholarship.com"
}

module "hrblock" {
  source = "../applications/longshot"

  name        = "longshot-hrblock"
  domain      = "caps.hrblock.com"
  pipeline    = "${heroku_pipeline.longshot.id}"
  environment = "production"

  email_name    = "Kary at CAPS"
  email_address = "contracts@tmiagency.org"

  papertrail_destination = "${var.papertrail_prod_destination}"
}

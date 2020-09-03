variable "heroku_email" {}
variable "heroku_api_key" {}
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

module "longshot-footlocker" {
  source = "../applications/longshot"

  name        = "longshot-footlocker"
  environment = "production"
}

module "longshot-footlocker-internal" {
  source = "../applications/longshot"

  name        = "longshot-footlocker-internal"
  environment = "production"
}

module "hrblock" {
  source = "../applications/longshot"

  name        = "longshot-hrblock"
  environment = "production"
}

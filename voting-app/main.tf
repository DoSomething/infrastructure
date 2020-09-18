variable "fastly_api_key" {}

terraform {
  backend "remote" {
    organization = "dosomething"

    workspaces {
      name = "voting-app"
    }
  }
}

provider "aws" {
  version = "2.30.0"
  region  = "us-east-1"
  profile = "terraform"
}

provider "fastly" {
  version = "0.9.0"
  api_key = var.fastly_api_key
}

module "agg" {
  source = "../applications/static"

  domain      = "www.athletesgonegood.com"
  environment = "production"
  stack       = "web"

  force_ssl = false # We don't have an SSL certificate for this domain.
}


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

resource "fastly_service_v1" "voting-app" {
  name          = "Terraform: Voting App"
  force_destroy = true

  domain {
    name = "www.athletesgonegood.com"
  }

  gzip {
    name = "gzip"

    extensions = ["css", "js", "html", "eot", "ico", "otf", "ttf", "json"]

    content_types = [
      "text/html",
      "application/x-javascript",
      "text/css",
      "application/javascript",
      "text/javascript",
      "application/json",
      "application/vnd.ms-fontobject",
      "application/x-font-opentype",
      "application/x-font-truetype",
      "application/x-font-ttf",
      "application/xml",
      "font/eot",
      "font/opentype",
      "font/otf",
      "image/svg+xml",
      "image/vnd.microsoft.icon",
      "text/plain",
      "text/xml",
    ]
  }

  backend {
    name    = "s3-www.athletesgonegood.com"
    address = module.agg.backend
    port    = 80
  }
}

module "agg" {
  source = "../applications/static"

  domain      = "www.athletesgonegood.com"
  environment = "production"
  stack       = "web"
}


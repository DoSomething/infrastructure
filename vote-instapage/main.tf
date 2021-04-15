variable "fastly_api_key" {}
variable "papertrail_destination" {}

terraform {
  backend "remote" {
    organization = "dosomething"

    workspaces {
      name = "vote-instapage"
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

variable "s3_routes" {
  default = "^/(static|vendor)"
}

resource "aws_s3_bucket" "vote" {
  bucket = "vote.dosomething.org"
  acl    = "public-read"

  # see: https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteAccessPermissionsReqd.html 
  policy = file("${path.module}/policy-vote.json")

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = {
    Application = "vote.dosomething.org"
    Environment = "production"
    Stack       = "web"
  }
}


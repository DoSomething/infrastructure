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

resource "fastly_service_v1" "vote" {
  name          = "Terraform: Voter Registration"
  force_destroy = true

  domain {
    name = "vote-fastly.dosomething.org"
  }

  domain {
    name = "vote.dosomething.org"
  }

  default_host = "vote.dosomething.org"

  backend {
    name    = "instapage"
    address = "secure.pageserve.co"
    port    = 80
  }

  backend {
    name              = "s3"
    request_condition = "backend-s3"
    address           = "${aws_s3_bucket.vote.bucket}.s3-website-${aws_s3_bucket.vote.region}.amazonaws.com"
    port              = 80
  }

  condition {
    type      = "REQUEST"
    name      = "backend-s3"
    statement = "req.url ~ \"${var.s3_routes}\""
  }

  condition {
    type      = "CACHE"
    name      = "cache-not-s3"
    statement = "req.url !~ \"${var.s3_routes}\""
  }

  cache_setting {
    name            = "force-pass"
    action          = "pass"
    cache_condition = "cache-not-s3"
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

  request_setting {
    name      = "Force SSL"
    force_ssl = true
  }

  snippet {
    name    = "Redirects Table"
    type    = "init"
    content = file("${path.module}/redirects_table.vcl")
  }

  snippet {
    name    = "Trigger Redirect"
    type    = "recv"
    content = file("${path.module}/trigger_redirect.vcl")
  }

  snippet {
    name    = "Handle Redirect"
    type    = "error"
    content = file("${path.module}/handle_redirect.vcl")
  }

  condition {
    type      = "RESPONSE"
    name      = "errors"
    statement = "resp.status > 399 && resp.status < 600"
  }

  papertrail {
    name               = "vote.dosomething.org"
    address            = element(split(":", var.papertrail_destination), 0)
    port               = element(split(":", var.papertrail_destination), 1)
    format             = "%t '%r' status=%>s bytes=%b microseconds=%D"
    response_condition = "errors"
  }
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


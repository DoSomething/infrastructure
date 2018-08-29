resource "fastly_service_v1" "voting-app" {
  name          = "Terraform: Voting App"
  force_destroy = true

  domain {
    name = "www.celebsgonegood.com"
  }

  domain {
    name = "www.athletesgonegood.com"
  }

  domain {
    name = "www.fourleggedfinishers.com"
  }

  backend {
    address = "54.172.90.245"
    name    = "HAProxy"
    port    = 80
  }

  header {
    name        = "Country Code"
    type        = "request"
    action      = "set"
    source      = "geoip.country_code"
    destination = "http.X-Fastly-Country-Code"
  }

  header {
    name        = "Country Code (Debug)"
    type        = "response"
    action      = "set"
    source      = "geoip.country_code"
    destination = "http.X-Fastly-Country-Code"
  }
}

resource "aws_s3_bucket" "cgg" {
  bucket = "www.celebsgonegood.com"
  acl    = "public-read"

  # see: https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteAccessPermissionsReqd.html 
  policy = "${file("${path.module}/policy-cgg.json")}"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_bucket" "agg" {
  bucket = "www.athletesgonegood.com"
  acl    = "public-read"

  # see: https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteAccessPermissionsReqd.html 
  policy = "${file("${path.module}/policy-agg.json")}"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

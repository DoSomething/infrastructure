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

  condition {
    type      = "REQUEST"
    name      = "backend-celebsgonegood"
    statement = "req.http.host == \"www.celebsgonegood.com\""
  }

  condition {
    type      = "REQUEST"
    name      = "backend-athletesgonegood"
    statement = "req.http.host == \"www.athletesgonegood.com\""
  }

  backend {
    name              = "s3-www.celebsgonegood.com"
    address           = "${aws_s3_bucket.cgg.bucket}.s3-website-${aws_s3_bucket.cgg.region}.amazonaws.com"
    request_condition = "backend-celebsgonegood"
    port              = 80
  }

  backend {
    name              = "s3-www.athletesgonegood.com"
    address           = "${aws_s3_bucket.agg.bucket}.s3-website-${aws_s3_bucket.agg.region}.amazonaws.com"
    request_condition = "backend-athletesgonegood"
    port              = 80
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

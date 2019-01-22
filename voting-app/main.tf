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
    address = "${aws_s3_bucket.agg.bucket}.s3-website-${aws_s3_bucket.agg.region}.amazonaws.com"
    port    = 80
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

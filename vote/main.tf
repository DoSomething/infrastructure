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
    statement = "req.url ~ \"^/(static|vendor)\""
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

  vcl {
    main = true
    name = "main"

    # @TODO: Separate into snippets once Terraform adds support.
    content = "${file("${path.module}/custom.vcl")}"
  }
}

resource "aws_s3_bucket" "vote" {
  bucket = "vote.dosomething.org"
  acl    = "public-read"

  # see: https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteAccessPermissionsReqd.html 
  policy = "${file("${path.module}/policy-vote.json")}"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

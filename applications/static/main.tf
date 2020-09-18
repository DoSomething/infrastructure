variable "domain" {
  description = "The domain this bucket will be accessible at, e.g. assets.dosomething.org"
}

variable "environment" {
  description = "The environment for this bucket: development, qa, or production."
}

variable "stack" {
  description = "The 'stack' for this bucket: web, sms, backend, data."
}

resource "fastly_service_v1" "cdn" {
  name          = "Terraform: ${var.domain}"
  force_destroy = true

  domain {
    name = var.domain
  }

  backend {
    name    = "s3-${var.domain}"
    address = "${aws_s3_bucket.bucket.id}.s3-website-${aws_s3_bucket.bucket.region}.amazonaws.com"
    port    = 80
  }

  request_setting {
    name      = "Force SSL"
    force_ssl = true
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

  # The S3 backend only returns a 'Vary' header if a request has a CORS header on it, which
  # means we may accidentally cache a CORS-less response for everyone. This rule adds the
  # expected 'Vary' if it isn't already set on the response.
  header {
    name        = "S3 Vary"
    type        = "cache"
    action      = "set"
    destination = "http.Vary"
    source      = "\"Origin, Access-Control-Request-Headers, Access-Control-Request-Method\""
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.domain
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  cors_rule {
    allowed_methods = ["GET"]

    # Allow CORS requests from DS.org properties & local development apps.
    allowed_origins = ["https://*.dosomething.org", "http://*.test"]
  }

  tags = {
    Application = var.domain
    Environment = var.environment
    Stack       = var.stack
  }
}

resource "aws_s3_bucket_object" "index" {
  bucket       = aws_s3_bucket.bucket.id
  key          = "index.html"
  content_type = "text/html"

  # We hard-code this module's path (from the root) here to avoid an issue
  # where ${path.module} marks this as "dirty" on different machines.
  source = "applications/static/default.index.html"
}

resource "aws_s3_bucket_object" "error" {
  bucket       = aws_s3_bucket.bucket.id
  key          = "error.html"
  content_type = "text/html"

  # We hard-code this module's path (from the root) here to avoid an issue
  # where ${path.module} marks this as "dirty" on different machines.
  source = "applications/static/default.error.html"
}

data "template_file" "public_bucket_policy" {
  # see: https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteAccessPermissionsReqd.html 
  template = file("${path.module}/bucket-policy.json.tpl")

  vars = {
    bucket_arn = aws_s3_bucket.bucket.arn
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.template_file.public_bucket_policy.rendered
}

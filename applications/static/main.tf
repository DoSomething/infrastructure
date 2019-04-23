variable "domain" {
  description = "The domain this bucket will be accessible at, e.g. assets.dosomething.org"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.domain}"
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["https://*.dosomething.org", "http://*.test"]

    # expose_headers  = ["ETag"]
    # max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_object" "index" {
  bucket       = "${aws_s3_bucket.bucket.id}"
  key          = "index.html"
  content_type = "text/html"

  # We hard-code this module's path (from the root) here to avoid an issue
  # where ${path.module} marks this as "dirty" on different machines.
  source = "applications/static/default.index.html"
}

resource "aws_s3_bucket_object" "error" {
  bucket       = "${aws_s3_bucket.bucket.id}"
  key          = "error.html"
  content_type = "text/html"

  # We hard-code this module's path (from the root) here to avoid an issue
  # where ${path.module} marks this as "dirty" on different machines.
  source = "applications/static/default.error.html"
}

data "template_file" "public_bucket_policy" {
  # see: https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteAccessPermissionsReqd.html 
  template = "${file("${path.module}/bucket-policy.json.tpl")}"

  vars {
    bucket_arn = "${aws_s3_bucket.bucket.arn}"
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = "${aws_s3_bucket.bucket.id}"
  policy = "${data.template_file.public_bucket_policy.rendered}"
}

output "backend" {
  value = "${aws_s3_bucket.bucket.id}.s3-website-${aws_s3_bucket.bucket.region}.amazonaws.com"
}

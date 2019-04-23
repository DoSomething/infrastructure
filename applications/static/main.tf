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

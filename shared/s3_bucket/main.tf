# Required variables:
variable "name" {
  description = "The name for this bucket (usually the application name)."
}

variable "user" {
  description = "The IAM user to grant permissions to read/write to this bucket."
}

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.name}"
  acl    = "public-read"

  tags {
    Application = "${var.name}"
  }
}

data "template_file" "s3_policy" {
  template = "${file("${path.root}/shared/s3-policy.json.tpl")}"

  vars {
    bucket_arn = "${aws_s3_bucket.bucket.arn}"
  }
}

resource "aws_iam_user_policy" "s3_policy" {
  name   = "${var.name}-s3"
  user   = "${var.user}"
  policy = "${data.template_file.s3_policy.rendered}"
}

output "id" {
  value = "${aws_s3_bucket.bucket.id}"
}

output "region" {
  value = "${aws_s3_bucket.bucket.region}"
}

output "laravel_config" {
  value = {
    STORAGE_DRIVER = "s3"
    S3_REGION      = "${aws_s3_bucket.bucket.region}"
    S3_BUCKET      = "${aws_s3_bucket.bucket.id}"
  }
}

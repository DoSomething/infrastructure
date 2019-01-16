# Required variables:
variable "name" {
  description = "The name for this bucket (usually the application name)."
}

variable "user" {
  description = "The IAM user to grant permissions to read/write to this bucket."
}

# Optional variables:
variable "acl" {
  description = "The canned ACL for this bucket. See: https://goo.gl/TFnRSY"
  default     = "public-read"
}

variable "versioning" {
  description = "Enable versioning on this bucket. See: https://goo.gl/idPRVV"
  default     = false
}

variable "replication" {
  description = "Enable cross-region replication on this bucket. See: https://goo.gl/zt3QNn"
  default     = false
}

variable "force_public" {
  description = "Force 'public read' permissions for objects. Not recommended."
  default     = false
}

locals {
  bucket_id     = "${var.replication ? join("", aws_s3_bucket.replicated_bucket.*.id) : join("", aws_s3_bucket.bucket.*.id)}"
  bucket_region = "${var.replication ? join("", aws_s3_bucket.replicated_bucket.*.region) : join("", aws_s3_bucket.bucket.*.region)}"
  bucket_arn    = "${var.replication ? join("", aws_s3_bucket.replicated_bucket.*.arn) : join("", aws_s3_bucket.bucket.*.arn)}"
}

# Without 'replication' enabled:
resource "aws_s3_bucket" "bucket" {
  count  = "${var.replication ? 0 : 1}"
  bucket = "${var.name}"
  acl    = "${var.acl}"

  versioning {
    enabled = "${var.versioning}"
  }

  tags {
    Application = "${var.name}"
  }
}

# With 'replication' enabled:
resource "random_id" "replication_rules" {
  count       = "${var.replication ? 1 : 0}"
  byte_length = 32
}

# TODO: In Terraform 0.12, these two s3_bucket resources can
# be combined with dynamic blocks! https://git.io/fhlmD
resource "aws_s3_bucket" "replicated_bucket" {
  count  = "${var.replication ? 1 : 0}"
  bucket = "${var.name}"
  acl    = "${var.acl}"

  versioning {
    enabled = true # Versioning must be enabled for replication to work.
  }

  replication_configuration {
    role = "${aws_iam_role.replication.arn}"

    rules {
      id     = "${random_id.replication_rules.b64_std}"
      status = "Enabled"

      destination {
        bucket        = "${aws_s3_bucket.backup.arn}"
        storage_class = "STANDARD_IA"
      }
    }
  }

  tags {
    Application = "${var.name}"
  }
}

data "template_file" "s3_policy" {
  template = "${file("${path.module}/iam-policy.json.tpl")}"

  vars {
    bucket_arn = "${local.bucket_arn}"
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  count = "${var.force_public ? 1 : 0}"

  bucket = "${local.bucket_id}"
  policy = "${data.template_file.public_bucket_policy.rendered}"
}

data "template_file" "public_bucket_policy" {
  template = "${file("${path.module}/public-bucket-policy.json.tpl")}"

  vars {
    bucket_arn = "${local.bucket_arn}"
  }
}

resource "aws_iam_user_policy" "s3_policy" {
  name   = "${var.name}-s3"
  user   = "${var.user}"
  policy = "${data.template_file.s3_policy.rendered}"
}

resource "random_id" "lifecycle_rules" {
  count       = "${var.replication ? 1 : 0}"
  byte_length = 32
}

resource "aws_s3_bucket" "backup" {
  count  = "${var.replication ? 1 : 0}"
  bucket = "${var.name}-backup"
  region = "us-west-1"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "${random_id.lifecycle_rules.b64_std}"
    enabled = true

    # Since we can't replicate directly into Glacier, set a lifecycle
    # rule to move these backups there after 30 days.
    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }
}

resource "aws_iam_role" "replication" {
  count              = "${var.replication ? 1 : 0}"
  name               = "${var.name}-s3-replication"
  assume_role_policy = "${file("${path.module}/replication-role.json")}"
}

data "template_file" "replication_policy" {
  count    = "${var.replication ? 1 : 0}"
  template = "${file("${path.module}/replication-policy.json.tpl")}"

  vars {
    source_bucket_arn      = "${aws_s3_bucket.replicated_bucket.arn}"
    destination_bucket_arn = "${aws_s3_bucket.backup.arn}"
  }
}

resource "aws_iam_policy" "replication" {
  count  = "${var.replication ? 1 : 0}"
  name   = "${var.name}-replication-policy"
  policy = "${data.template_file.replication_policy.rendered}"
}

resource "aws_iam_policy_attachment" "replication" {
  count      = "${var.replication ? 1 : 0}"
  name       = "${var.name}-replication-role-attachment"
  roles      = ["${aws_iam_role.replication.name}"]
  policy_arn = "${aws_iam_policy.replication.arn}"
}

output "id" {
  value = "${local.bucket_id}"
}

output "region" {
  value = "${local.bucket_region}"
}

output "config_vars" {
  value = {
    STORAGE_DRIVER = "s3"
    S3_BUCKET      = "${local.bucket_id}"
    S3_REGION      = "${local.bucket_region}"
  }
}

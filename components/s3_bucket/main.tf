# Required variables:
variable "name" {
  description = "The name for this bucket (usually the application name)."
}

variable "user" {
  description = "The IAM user to grant permissions to read/write to this bucket."
  default     = null
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

variable "archived" {
  description = "Should the contents of this bucket be archived to Glacier?"
  default     = false
}

variable "replication_target" {
  description = "Configure replication rules to the target bucket."
  default     = null
}

variable "force_public" {
  description = "Force 'public read' permissions for objects. Not recommended."
  default     = false
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.name
  acl    = var.acl

  versioning {
    # Versioning must be enabled if we have a replication target.
    enabled = var.versioning || var.replication_target != null
  }

  dynamic "lifecycle_rule" {
    # Hack: only attach a lifecycle rule if we are archiving to Glacier.
    for_each = var.archived ? [1] : []

    content {
      id      = random_id.lifecycle_rule_id[0].b64_std
      enabled = true

      # Since we can't replicate directly into Glacier, set a lifecycle
      # rule to move these backups there after 30 days.
      transition {
        days          = 30
        storage_class = "GLACIER"
      }
    }
  }

  dynamic "replication_configuration" {
    # Only configure replication if a target bucket is given. (We have to use
    # for_each since there isn't just a single "conditional" arg, and we first
    # check against null so we don't create a [null] iterator & fail reading
    # the 'arn' property off the bucket below.)
    for_each = var.replication_target != null ? [var.replication_target] : []

    content {
      role = aws_iam_role.replication[0].arn

      rules {
        id     = random_id.replication_rules[0].b64_std
        status = "Enabled"

        destination {
          bucket        = replication_configuration.value.arn
          storage_class = "STANDARD_IA"
        }
      }
    }
  }

  tags = {
    Application = var.name
  }
}

# Glacier:
resource "random_id" "lifecycle_rule_id" {
  count = var.archived == true ? 1 : 0
  byte_length = 32
}

# IAM policy:
data "template_file" "s3_policy" {
  count = var.user != null ? 1 : 0
  template = file("${path.module}/iam-policy.json.tpl")

  vars = {
    bucket_arn = aws_s3_bucket.bucket.arn
  }
}

resource "aws_iam_user_policy" "s3_policy" {
  count = var.user != null ? 1 : 0

  name   = "${var.name}-s3"
  user   = var.user
  policy = data.template_file.s3_policy[0].rendered
}

# Optional "force public" bucket policy:
resource "aws_s3_bucket_policy" "bucket_policy" {
  count = var.force_public ? 1 : 0

  bucket = aws_s3_bucket.bucket.id
  policy = data.template_file.public_bucket_policy.rendered
}

data "template_file" "public_bucket_policy" {
  template = file("${path.module}/public-bucket-policy.json.tpl")

  vars = {
    bucket_arn = aws_s3_bucket.bucket.arn
  }
}

# Replication rules:
resource "random_id" "replication_rules" {
  count       = var.replication_target != null ? 1 : 0
  byte_length = 32
}

resource "aws_iam_role" "replication" {
  count       = var.replication_target != null ? 1 : 0

  name               = "${var.name}-s3-replication"
  assume_role_policy = file("${path.module}/replication-role.json")
}

data "template_file" "replication_policy" {
  count       = var.replication_target != null ? 1 : 0

  template = file("${path.module}/replication-policy.json.tpl")

  vars = {
    source_bucket_arn      = aws_s3_bucket.bucket.arn
    destination_bucket_arn = var.replication_target.arn
  }
}

resource "aws_iam_policy" "replication" {
  count       = var.replication_target != null ? 1 : 0

  name   = "${var.name}-replication-policy"
  policy = data.template_file.replication_policy[0].rendered
}

resource "aws_iam_policy_attachment" "replication" {
  count       = var.replication_target != null ? 1 : 0

  name       = "${var.name}-replication-role-attachment"
  roles      = [aws_iam_role.replication[0].name]
  policy_arn = aws_iam_policy.replication[0].arn
}

output "id" {
  value = aws_s3_bucket.bucket.id
}

output "region" {
  value = aws_s3_bucket.bucket.region
}

output "bucket" {
  value = aws_s3_bucket.bucket
}

output "config_vars" {
  value = {
    STORAGE_DRIVER = "s3"
    S3_BUCKET      = aws_s3_bucket.bucket.id
    S3_REGION      = aws_s3_bucket.bucket.region
  }
}


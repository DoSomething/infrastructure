# Required variables:
variable "name" {
  description = "The name for this bucket (usually the application name)."
}

variable "application" {
  description = "The application this bucket is provisioned for (e.g. 'dosomething-rogue')."
}

variable "environment" {
  description = "The environment for this bucket: development, qa, or production."
}

variable "stack" {
  description = "The 'stack' for this bucket: web, sms, backend, data."
}

# Optional variables:
variable "user" {
  description = "The IAM user to grant permissions to read/write to this bucket."
  default     = null
}

variable "roles" {
  description = "The IAM roles which should have access to this bucket."
  type        = list(string)
  default     = []
}

variable "versioning" {
  description = "Enable versioning on this bucket. See: https://goo.gl/idPRVV"
  default     = false
}

variable "archived" {
  description = "Should the contents of this bucket be archived to Glacier?"
  default     = false
}

variable "private" {
  description = "Should we force all objects in this bucket to be private?"
  default     = true
}

variable "replication_target" {
  description = "Configure replication rules to the target bucket."
  default     = null
}

locals {
  s3_policy = templatefile("${path.module}/iam-policy.json.tpl", { bucket_arn = aws_s3_bucket.bucket.arn })
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.name

  # The canned ACL for this bucket. See: https://goo.gl/TFnRSY
  acl = var.private ? "private" : "public-read"

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
    Application = var.application
    Environment = var.environment
    Stack       = var.stack
  }
}

# Glacier:
resource "random_id" "lifecycle_rule_id" {
  count       = var.archived == true ? 1 : 0
  byte_length = 32
}

# IAM policy:
resource "aws_iam_user_policy" "s3_policy" {
  count = var.user != null ? 1 : 0

  name   = "${var.name}-s3"
  user   = var.user
  policy = local.s3_policy
}

resource "aws_iam_policy" "s3_role_policy" {
  count = length(var.roles) >= 1 ? 1 : 0
  name  = "${var.name}-s3"
  path  = "/"

  policy = local.s3_policy
}

resource "aws_iam_role_policy_attachment" "s3_role_policy" {
  count      = length(var.roles)
  role       = var.roles[count.index]
  policy_arn = aws_iam_policy.s3_role_policy[0].arn
}

# 'Public Access Block' configuration:
resource "aws_s3_bucket_public_access_block" "private_policy" {
  count  = var.private ? 1 : 0
  bucket = aws_s3_bucket.bucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
}

# Replication rules:
resource "random_id" "replication_rules" {
  count       = var.replication_target != null ? 1 : 0
  byte_length = 32
}

resource "aws_iam_role" "replication" {
  count = var.replication_target != null ? 1 : 0

  name               = "${var.name}-s3-replication"
  assume_role_policy = file("${path.module}/replication-role.json")
}

data "template_file" "replication_policy" {
  count = var.replication_target != null ? 1 : 0

  template = file("${path.module}/replication-policy.json.tpl")

  vars = {
    source_bucket_arn      = aws_s3_bucket.bucket.arn
    destination_bucket_arn = var.replication_target.arn
  }
}

resource "aws_iam_policy" "replication" {
  count = var.replication_target != null ? 1 : 0

  name   = "${var.name}-replication-policy"
  policy = data.template_file.replication_policy[0].rendered
}

resource "aws_iam_policy_attachment" "replication" {
  count = var.replication_target != null ? 1 : 0

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


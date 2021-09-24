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
    for_each = var.temporary_paths

    content {
      prefix  = lifecycle_rule.value
      enabled = true

      # Delete files in this path after two weeks:
      expiration {
        days = 14
      }

      # If versioned, delete non-current versions at this path after 3 months:
      noncurrent_version_expiration {
        days = 90
      }
    }
  }

  dynamic "lifecycle_rule" {
    # Hack: only attach a lifecycle rule if we are archiving to Glacier.
    for_each = var.archived ? [1] : []

    content {
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
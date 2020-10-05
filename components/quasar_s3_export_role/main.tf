resource "aws_s3_bucket" "dosomething_quasar_archive" {
  bucket = "dosomething-quasar-archive"
  acl    = "private"

  lifecycle_rule {
    id      = "archive"
    enabled = true

    prefix = "archive/"

    tags = {
      "rule" = "archive"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA" # or "ONEZONE_IA"
    }

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 60
    }

  }
}

resource "aws_s3_bucket_public_access_block" "private_policy" {
  bucket = aws_s3_bucket.dosomething_quasar_archive.id

  # We don't want to risk a bug causing individual
  # log files to be marked with "public" ACLs.
  block_public_acls  = true
  ignore_public_acls = true

}

data "aws_iam_policy_document" "quasar_s3_export_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["export.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "policy" {
  name   = "ExportPolicy"
  policy = templatefile("${path.module}/iam-policy.json.tpl", { bucket_arn = aws_s3_bucket.dosomething_quasar_archive.arn })
}

resource "aws_iam_role" "role" {
  name               = "rds-s3-export-role"
  description        = "Role for exporting Quasar RDS snapshots to S3."
  assume_role_policy = data.aws_iam_policy_document.quasar_s3_export_role.json
}

resource "aws_iam_role_policy_attachment" "attachment" {
  role       = "${aws_iam_role.role.name}"
  policy_arn = "${aws_iam_policy.policy.arn}"
}

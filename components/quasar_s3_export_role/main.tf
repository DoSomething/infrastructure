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
  policy = templatefile("${path.module}/iam-policy.json.tpl")
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

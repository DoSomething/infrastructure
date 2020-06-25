data "aws_ssm_parameter" "external_id" {
  name = "/fivetran/${var.environment}/external-id"
}

data "aws_iam_policy_document" "fivetran_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::834469178297:root"] # Fivetran's Account ID
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"

      values = [
        # This is the the 'External ID' secret provided by Fivetran.
        data.aws_ssm_parameter.external_id.value,
      ]
    }
  }
}

resource "aws_iam_policy" "policy" {
  name = "${var.name}-s3-fivetran"
  policy = templatefile("${path.module}/iam-policy.json.tpl", {
    bucket_arn = var.bucket.arn
  })
}

resource "aws_iam_role" "role" {
  name               = "${var.name}-s3-fivetran"
  description        = "Role for Fivetran S3 Connector."
  assume_role_policy = data.aws_iam_policy_document.fivetran_assume_role.json

  tags = {
    Application = "Fivetran"
  }
}

resource "aws_iam_role_policy_attachment" "attachment" {
  role       = "${aws_iam_role.role.name}"
  policy_arn = "${aws_iam_policy.policy.arn}"
}

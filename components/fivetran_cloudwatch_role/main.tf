locals {
  fivetran_cloudwatch_policy = templatefile("${path.module}/iam-policy.json.tpl")
}

data "aws_iam_policy_document" "fivetran_cloudwatch_integration_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      # Fivetran Account ID
      identifiers = ["arn:aws:iam::834469178297:root"]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"

      values = [
        var.fivetran_cloudwatch_integration_external_id,
      ]
    }
  }
}

data "aws_iam_policy_document" "fivetran_cloudwatch_integration" {
  statement {
    sid    = "FivetranCloudwatchIntegration"
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "fivetran_cloudwatch_integration" {
  name   = "FivetranCloudwatchIntegrationPolicy"
  policy = data.aws_iam_policy_document.fivetran_cloudwatch_integration.json
}

resource "aws_iam_role" "fivetran_cloudwatch_integration" {
  name               = "FivetranCloudwatchIntegrationRole"
  description        = "Role for Fivetran Cloudwatch Integration"
  assume_role_policy = data.aws_iam_policy_document.fivetran_cloudwatch_integration_assume_role.json
  tags = {
    Application = "Fivetran"
  }
}

resource "aws_iam_role_policy_attachment" "fivetran_aws_integration" {
  role       = aws_iam_role.fivetran_cloudwatch_integration.name
  policy_arn = aws_iam_policy.fivetran_cloudwatch_integration.arn
}

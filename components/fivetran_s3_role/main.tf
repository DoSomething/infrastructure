data "aws_ssm_parameter" "external_id" {
  name = "/fivetran/${var.environment}/external-id"
}

resource "aws_iam_policy" "fivetran_policy" {
  name = "${var.name}-s3-fivetran"
  policy = templatefile("${path.module}/iam-policy.json.tpl", {
    bucket_arn = var.bucket.arn
  })
}

resource "aws_iam_role" "fivetran_role" {
  name = "${var.name}-s3-fivetran"

  assume_role_policy = templatefile("${path.module}/iam-role.json.tpl", {
    fivetran_account_id = 834469178297
    external_id         = data.aws_ssm_parameter.external_id.value
  })
}

resource "aws_iam_role_policy_attachment" "fivetran_policy_attachment" {
  role       = "${aws_iam_role.fivetran_role.name}"
  policy_arn = "${aws_iam_policy.fivetran_policy.arn}"
}

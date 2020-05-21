resource "aws_iam_policy" "dynamodb_policy" {
  name = "${var.name}-dynamodb"
  path = "/"

  policy = templatefile("${path.module}/dynamodb-policy.json.tpl", { dynamodb_prefix = var.name })
}

resource "aws_iam_role_policy_attachment" "dynamodb_policy" {
  count      = length(var.roles)
  role       = var.roles[count.index]
  policy_arn = aws_iam_policy.dynamodb_policy.arn
}

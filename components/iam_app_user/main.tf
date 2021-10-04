resource "aws_iam_user" "aws_user" {
  name = var.name

  # When destroying this resource, destroy even if it has non-Terraform
  # managed access keys, policies, etc. See: https://git.io/JfP7O
  force_destroy = true
}

resource "aws_iam_access_key" "aws_key" {
  user = aws_iam_user.aws_user.name
}
variable "name" {
  description = "The application name."
}

resource "aws_iam_user" "aws_user" {
  name = var.name

  # When destroying this resource, destroy even if it has non-Terraform
  # managed access keys, policies, etc. See: https://git.io/JfP7O
  force_destroy = true
}

resource "aws_iam_access_key" "aws_key" {
  user = aws_iam_user.aws_user.name
}

output "name" {
  value = aws_iam_user.aws_user.name
}

output "id" {
  value = aws_iam_access_key.aws_key.id
}

output "secret" {
  value = aws_iam_access_key.aws_key.secret
}

output "config_vars" {
  value = {
    AWS_ACCESS_KEY_ID = aws_iam_access_key.aws_key.id
    AWS_SECRET_ACCESS_KEY = aws_iam_access_key.aws_key.secret

    # @TODO: Remove these old vars once safe to do so!
    AWS_ACCESS_KEY = aws_iam_access_key.aws_key.id
    AWS_SECRET_KEY = aws_iam_access_key.aws_key.secret
  }
}


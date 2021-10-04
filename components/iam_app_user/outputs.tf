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
    AWS_ACCESS_KEY_ID     = aws_iam_access_key.aws_key.id
    AWS_SECRET_ACCESS_KEY = aws_iam_access_key.aws_key.secret

    # @TODO: Remove these old vars once safe to do so!
    AWS_ACCESS_KEY = aws_iam_access_key.aws_key.id
    AWS_SECRET_KEY = aws_iam_access_key.aws_key.secret
  }
}

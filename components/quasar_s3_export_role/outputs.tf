output "role_arn" {
  description = "The Quasar Export Role ARN."
  value       = aws_iam_role.role.arn
}

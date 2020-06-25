output "role_arn" {
  description = "The Fivetran Role ARN. This is provided in the connector setup form."
  value       = aws_iam_role.fivetran_role.arn
}
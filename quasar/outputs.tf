output "RoleARN" {
  description = "AWS Role ARN to be used in Fivetran"
  value       = "${aws_iam_role.fivetran_cloudwatch_integration.arn}"
}
output "name" {
  description = "The name of the Lambda function."
  value       = aws_lambda_function.function.function_name
}

output "arn" {
  description = "The ARN (unique ID) of the Lambda function."
  value       = aws_lambda_function.function.arn
}

output "invoke_arn" {
  description = "The ARN (unique ID) used to invoke this function from API Gateway."
  value       = aws_lambda_function.function.invoke_arn
}

output "lambda_role" {
  description = "The execution role for this funciton. Use this to attach AWS permissions."
  value       = aws_iam_role.lambda_exec.name
}


variable "logger" {
  description = "The Lambda function ARN to subscribe to this function's log group."
  default     = ""
}

module "app" {
  source = "../../shared/lambda_function"

  name = "hello-serverless"
}

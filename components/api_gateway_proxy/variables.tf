# Required variables:
variable "name" {
  description = "The application name."
}

variable "environment" {
  description = "The environment for this gateway: development, qa, or production."
}

variable "stack" {
  description = "The 'stack' for this gateway: web, sms, backend, data."
}

variable "function_arn" {
  description = "The Lambda function's ARN."
}

variable "function_invoke_arn" {
  description = "The Lambda function's invocation ARN."
}

# Optional variables:
variable "domain" {
  description = "The domain this application will be accessible at, e.g. lambda.dosomething.org"

  # If omitted, we will just not attach a custom domain to this app. By default,
  # you can access a Lambda function at a URL returned in the `base_url` output.
  default = ""
}

variable "certificate" {
  description = "The ACM certificate to use for this domain, e.g. *.dosomething.org"
  default     = "*.dosomething.org"
}

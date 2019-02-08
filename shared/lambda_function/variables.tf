# Required variables:
variable "name" {
  description = "The application name."
}

variable "logger" {
  description = "The Lambda function ARN to subscribe to this function's log group."
  default     = ""
}

# Optional variables:
variable "config_vars" {
  description = "Environment variables for this application."

  default = {
    NODE_ENV = "production"
  }
}

variable "handler" {
  description = "The handler for this function."
  default     = "main.handler"
}

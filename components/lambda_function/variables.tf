# Required variables:
variable "name" {
  description = "The application name."
}

variable "runtime" {
  description = "The Lambda runtime to use. We support nodejs12.x, python2.7, and python3.7"
}

variable "handler" {
  description = "The handler for this Lambda, in the format 'file_name.function_name'."
  default     = "main.handler"
}

# Optional variables:
variable "config_vars" {
  description = "Environment variables for this application."

  # Lambda pouts if we provide an empty map here, so
  # let's just default to something reasonable.
  default = {
    NODE_ENV = "production"
  }
}

variable "logger" {
  description = "The Lambda function module to subscribe to this function's log group."
  default     = null
}


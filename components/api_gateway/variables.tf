# Required variables:
variable "name" {
  description = "The application name."
}

variable "functions_count" {
  # Temporary hack to work around Terraform 0.11 limitation. <https://git.io/fjLYC>
}

variable "functions" {
  description = "The functions that this gateway is allowed to invoke."
  type        = "list"
}

# The root route:
variable "root_function" {
  description = "The root route's function handler."
}

variable "root_method" {
  description = "The root route's HTTP method."
  default     = "ANY"
}

variable "root_authorization" {
  description = "The root route's authorization type."
  default     = "NONE"
}

variable "root_authorizer_id" {
  description = "If 'var.root_authorization' is 'CUSTOM', the Lambda to authorize with."
  default     = ""
}

# Additional routes:
variable "routes" {
  description = "A list of routes this gateway can respond to."

  default = []
}

variable "routes_count" {
  # Temporary hack to work around Terraform 0.11 limitation. <https://git.io/fjLYC>
}

# Optional custom domain support:
variable "domain" {
  description = "The domain this application will be accessible at, e.g. lambda.dosomething.org"

  # If omitted, we will just not attach a custom domain to this app. By default,
  # you can access a Lambda function at a URL returned in the `base_url` output.
  default = ""
}

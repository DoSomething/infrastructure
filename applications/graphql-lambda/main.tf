# Experimental: This module builds a serverless GraphQL instance.

variable "environment" {
  description = "The environment for this application: development, qa, or production."
}

variable "name" {
  description = "The application name."
}

variable "papertrail_destination" {
  description = "The Papertrail log destination for this application."
}

module "app" {
  source = "../../shared/lambda_function"

  name        = "${var.name}"
  environment = "${var.environment}"
}

output "backend" {
  value = "${module.app.backend}"
}

# Required variables:
variable "name" {
  description = "The DynamoDB table name."
}

variable "application" {
  description = "The application this cache is provisioned for (e.g. 'dosomething-graphql')."
}

variable "environment" {
  description = "The environment for this database: development, qa, or production."
}

variable "stack" {
  description = "The 'stack' for this database: web, sms, backend, data."
}

variable "roles" {
  description = "The IAM roles which should have access to this resource."
  type        = list(string)
}
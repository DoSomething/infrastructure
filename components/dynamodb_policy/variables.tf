# Required variables:
variable "name" {
  description = "The application name."
}

variable "roles" {
  description = "The IAM roles which should have access to DynamoDB."
  type        = list(string)
}

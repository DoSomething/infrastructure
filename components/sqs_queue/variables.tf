# Required variables:
variable "name" {
  description = "The name for this queue (usually the application name)."
}

variable "application" {
  description = "The application this queue is provisioned for (e.g. 'dosomething-northstar')."
}

variable "environment" {
  description = "The environment for this queue: development, qa, or production."
}

variable "stack" {
  description = "The 'stack' for this queue: web, sms, backend, data."
}

variable "user" {
  description = "The IAM user to grant permissions to read/write to this queue."
}

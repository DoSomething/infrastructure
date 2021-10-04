
# Required variables:
variable "name" {
  description = "The name for this bucket (usually the application name)."
}

variable "application" {
  description = "The application this bucket is provisioned for (e.g. 'dosomething-rogue')."
}

variable "environment" {
  description = "The environment for this bucket: development, qa, or production."
}

variable "stack" {
  description = "The 'stack' for this bucket: web, sms, backend, data."
}

# Optional variables:
variable "user" {
  description = "The IAM user to grant permissions to read/write to this bucket."
  default     = null
}

variable "roles" {
  description = "The IAM roles which should have access to this bucket."
  type        = list(string)
  default     = []
}

variable "temporary_paths" {
  description = "Automatically delete files in the following paths after 14 days."
  type        = list(string)
  default     = []
}

variable "versioning" {
  description = "Enable versioning on this bucket. See: https://goo.gl/idPRVV"
  default     = false
}

variable "archived" {
  description = "Should the contents of this bucket be archived to Glacier?"
  default     = false
}

variable "private" {
  description = "Should we force all objects in this bucket to be private?"
  default     = true
}

variable "replication_target" {
  description = "Configure replication rules to the target bucket."
  default     = null
}
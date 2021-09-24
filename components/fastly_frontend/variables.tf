variable "name" {
  description = "The name for this Fastly property."
  type        = string
}

variable "environment" {
  description = "The environment for this property: development, qa, or production."
}

variable "application" {
  description = "The application module to route traffic to."
  type        = object({ name = string, domain = string, backend = string })
}

variable "papertrail_destination" {
  description = "The Papertrail log destination to write logs to."
  type        = string
}

variable "name" {
  description = "The name for this Fastly property."
  type        = string
}

variable "applications" {
  description = "The application modules to route traffic to."
  type        = list(object({ name = string, domain = string, backend = string }))
}

variable "papertrail_destination" {
  description = "The Papertrail log destination to write logs to."
  type        = string
}

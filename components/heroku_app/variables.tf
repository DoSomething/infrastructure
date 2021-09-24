# Required variables:
variable "environment" {
  description = "The environment for this application: development, qa, or production."
}

variable "pipeline" {
  description = "The Heroku pipeline ID this application should be created in."
}

variable "name" {
  description = "The application name."
}

variable "framework" {
  description = "The framework for this application (e.g. 'laravel', 'express')."
}

variable "papertrail_destination" {
  description = "The Papertrail log destination for this application."
}

variable "domain" {
  description = "The domain this application will be accessible at, e.g. longshot.dosomething.org"
}

# Optional variables:
variable "web_size" {
  description = "The Heroku dyno type for web processes."
  default     = "Standard-1X"
}

variable "web_scale" {
  description = "The number of web dynos this application should have."
  default     = "1"
}

variable "ignore_web" {
  description = "Should we manage the web dyno with Terraform? Set to 'true' if auto-scaling."
  default     = false
}

variable "queue_size" {
  description = "The Heroku dyno type for queue processes."
  default     = "Standard-1X"
}

variable "queue_scale" {
  description = "The number of queue dynos this application should have."
  default     = "1"
}

variable "config_vars" {
  description = "Environment variables for this application."
  default     = {}
}

variable "with_newrelic" {
  description = "Should New Relic be configured for this app? Generally only used on prod."
  default     = false
}

variable "with_redis" {
  description = "Should we create a Redis store for this application?"
  default     = false
}

variable "redis_type" {
  # See usage below for default value. <https://stackoverflow.com/a/51758050/811624>
  description = "The Heroku Redis add-on plan. See: https://goo.gl/3v3RXX"
  default     = ""
}
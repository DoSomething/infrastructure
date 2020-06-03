# This template manages resources for old Longshot apps,
# a retired scholarship application run by DSS. We now use
# Heroku to handle SSL redirects & S3 to keep old storage.

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

variable "domain" {
  description = "The domain this application will be accessible at, e.g. longshot.dosomething.org"
}

variable "papertrail_destination" {
  description = "The Papertrail log destination for this application."
}

variable "deprecated" {
  description = "Deprecate this application, removing database users & allowing deletion."
  default     = false
}

module "app" {
  source = "../../components/heroku_app"

  framework   = "express"
  name        = var.name
  domain      = var.domain
  pipeline    = var.pipeline
  environment = var.environment

  web_scale   = 1
  queue_scale = 0

  papertrail_destination = var.papertrail_destination
  with_newrelic          = false
}


module "iam_user" {
  source = "../../components/iam_app_user"
  name   = var.name
}

module "storage" {
  source  = "../../components/s3_bucket"
  name    = var.name
  private = true
}

output "name" {
  value = var.name
}

output "domain" {
  value = var.domain
}

output "backend" {
  value = module.app.backend
}


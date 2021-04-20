# Required variables:
variable "environment" {
  description = "The environment for this application: development, qa, or production."
}

variable "name" {
  description = "The application name."
}

variable "deprecated" {
  description = "Deprecate this app, removing database users & allowing deletion."
  default     = false
}

locals {
  # This application is part of our backend stack.
  stack = "backend"
}

module "database" {
  source = "../../components/mariadb_instance"

  name        = var.name
  environment = var.environment
  stack       = local.stack

  instance_class = var.environment == "production" ? "db.m4.large" : "db.t2.medium"
  multi_az       = var.environment == "production"
  is_dms_source  = true
  deprecated     = var.deprecated
}

output "name" {
  value = var.name
}

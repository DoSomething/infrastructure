# Required variables:
variable "name" {
  description = "The identifier for the database instance (usually the application name)."
}

variable "environment" {
  description = "The environment for this database: development, qa, or production."
}

variable "stack" {
  description = "The 'stack' for this database: web, sms, backend, data."
}

variable "instance_class" {
  description = "The RDS instance class. See: https://goo.gl/vTMqx9"
}

# Optional variables:
variable "engine_version" {
  description = "The version of MariaDB to use on this instance."
  default     = "10.3"
}

variable "allocated_storage" {
  description = "The amount of storage to allocate to the database, in GB."
  default     = 100
}

variable "database_name" {
  # See usage below for default value. <https://stackoverflow.com/a/51758050/811624>
  description = "Optionally, the name for the database that should be provisioned at creation."
  default     = ""
}

variable "multi_az" {
  description = "Should this instance be Multi-AZ for enhanced durability/availability? See: https://goo.gl/dqDazn"
  default     = false
}

variable "subnet_group" {
  description = "The AWS subnet group name for this database."
  default     = "rds-mysql"
}

variable "security_groups" {
  description = "The security group IDs for this database."

  # TODO: Either update default security group to work here, or import
  # this as part of a "environment" module in Terraform 0.12.
  default = ["sg-a37efac7"]
}

variable "is_dms_source" {
  description = "Is this an Amazon DMS source? If so, sets appropriate parameters."
  default     = false
}

variable "deprecated" {
  description = "Deprecate this instance, removing users & allowing deletion."
  default     = false
}

# Required variables:
variable "name" {
  description = "The identifier for the database instance (usually the application name)."
}

variable "environment" {
  description = "The environment for this database: development, qa, or production."
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

# Data resources:
data "aws_ssm_parameter" "database_username" {
  name = "/${var.name}/rds/username"
}

data "aws_ssm_parameter" "database_password" {
  name = "/${var.name}/rds/password"
}

locals {
  # Should backups be enabled, and if so for how long? We keep backups for
  # the maximum window (30 days) on production, and otherwise the minimum
  # amount in order to satisfy functionality.
  base_backup_retention = "${var.is_dms_source ? 1 : 0}"

  backup_retention = "${var.environment == "production" ? 30 : local.base_backup_retention}"
}

resource "aws_db_parameter_group" "replication_settings" {
  count = "${var.is_dms_source ? 1 : 0}"

  name   = "${var.name}"
  family = "mariadb10.3"

  # These two parameters are required for Amazon
  # DMS replication sources. <https://goo.gl/yjNZ9u>
  parameter {
    name  = "binlog_format"
    value = "ROW"
  }

  parameter {
    name  = "binlog_checksum"
    value = "NONE"
  }
}

resource "aws_db_instance" "database" {
  identifier = "${var.name}"
  name       = "${replace(coalesce(var.database_name, var.name), "-", "_")}"

  engine            = "mariadb"
  engine_version    = "${var.engine_version}"
  instance_class    = "${var.instance_class}"
  allocated_storage = "${var.allocated_storage}"
  multi_az          = "${var.multi_az}"

  parameter_group_name = "${coalesce(join("", aws_db_parameter_group.replication_settings.*.id), "default.mariadb10.3")}"

  allow_major_version_upgrade = true

  backup_retention_period = "${local.backup_retention}" # See above!
  backup_window           = "06:00-07:00"               # 1-2am ET.

  enabled_cloudwatch_logs_exports = ["error", "slowquery"]

  username = "${data.aws_ssm_parameter.database_username.value}"
  password = "${data.aws_ssm_parameter.database_password.value}"

  # TODO: We should migrate our account out of EC2-Classic, create
  # a default VPC, and let resources be created in there by default!
  db_subnet_group_name = "${var.subnet_group}"

  vpc_security_group_ids = "${var.security_groups}"
  publicly_accessible    = true

  deletion_protection = "${! var.deprecated}"

  tags = {
    Application = "${var.name}"
  }
}

# Configure a MySQL provider for this instance.
provider "mysql" {
  version  = "~> 1.5"
  endpoint = "${aws_db_instance.database.endpoint}"
  username = "${aws_db_instance.database.username}"
  password = "${aws_db_instance.database.password}"
}

resource "random_string" "readonly_password" {
  length = 24

  # We can't use '@' or '$' in MySQL passwords.
  override_special = "!#%&*()-_=+[]{}<>:?"
}

resource "mysql_user" "readonly" {
  count              = "${var.deprecated ? 0 : 1}"
  user               = "readonly"
  host               = "%"
  plaintext_password = "${random_string.readonly_password.result}"
}

resource "mysql_grant" "readonly" {
  count      = "${var.deprecated ? 0 : 1}"
  user       = "${mysql_user.readonly.user}"
  host       = "${mysql_user.readonly.host}"
  database   = "${aws_db_instance.database.name}"
  privileges = ["SELECT"]
}

output "address" {
  value = "${aws_db_instance.database.address}"
}

output "port" {
  value = "${aws_db_instance.database.port}"
}

output "name" {
  value = "${aws_db_instance.database.name}"
}

output "username" {
  value = "${data.aws_ssm_parameter.database_username.value}"
}

output "password" {
  value = "${data.aws_ssm_parameter.database_password.value}"
}

output "config_vars" {
  value = {
    DB_HOST     = "${aws_db_instance.database.address}"
    DB_PORT     = "${aws_db_instance.database.port}"
    DB_DATABASE = "${aws_db_instance.database.name}"
    DB_USERNAME = "${data.aws_ssm_parameter.database_username.value}"
    DB_PASSWORD = "${data.aws_ssm_parameter.database_password.value}"
  }
}

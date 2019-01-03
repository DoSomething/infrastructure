# Required variables:
variable "name" {
  description = "The identifier for the database instance (usually the application name)."
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

variable "subnet_group" {
  description = "The AWS subnet group name for this database."
  default     = "rds-mysql"
}

variable "security_groups" {
  description = "The security group IDs for this database."
  default     = ["sg-0dca7669"]
}

variable "deletion_protection" {
  description = "If enabled, this database cannot be deleted (by Terraform or anything else)."
  default     = true
}

# Data resources:
data "aws_ssm_parameter" "database_username" {
  name = "/${var.name}/rds/username"
}

data "aws_ssm_parameter" "database_password" {
  name = "/${var.name}/rds/password"
}

resource "aws_db_instance" "database" {
  identifier = "${var.name}"
  name       = "${replace(coalesce(var.database_name, var.name), "-", "_")}"

  engine            = "mariadb"
  engine_version    = "${var.engine_version}"
  instance_class    = "${var.instance_class}"
  allocated_storage = "${var.allocated_storage}"

  allow_major_version_upgrade = true

  backup_retention_period = 7             # 7 days.
  backup_window           = "06:00-07:00" # 1-2am ET.

  username = "${data.aws_ssm_parameter.database_username.value}"
  password = "${data.aws_ssm_parameter.database_password.value}"

  # TODO: We should migrate our account out of EC2-Classic, create
  # a default VPC, and let resources be created in there by default!
  db_subnet_group_name = "${var.subnet_group}"

  vpc_security_group_ids = "${var.security_groups}"
  publicly_accessible    = true

  deletion_protection = "${var.deletion_protection}"

  tags = {
    Application = "${var.name}"
  }
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

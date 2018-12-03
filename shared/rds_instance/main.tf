# Required variables:
variable "name" {
  description = "The name for this database (usually the application name)."
}

variable "instance_class" {
  description = "The RDS instance class. See: https://goo.gl/vTMqx9"
}

# Optional variables:
variable "allocated_storage" {
  description = "The amount of storage to allocate to the database, in GB."
  default     = 100
}

variable "subnet_group" {
  description = "The AWS subnet group name for this database."
  default     = "default-vpc-7899331d"
}

variable "security_groups" {
  description = "The security group IDs for this database."
  default     = ["sg-c9a37db2"]
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
  name       = "longshot"

  engine            = "mariadb"
  engine_version    = "10.3"
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

output "laravel_config" {
  value = {
    DB_HOST     = "${aws_db_instance.database.address}"
    DB_PORT     = "${aws_db_instance.database.port}"
    DB_DATABASE = "${aws_db_instance.database.name}"
    DB_USERNAME = "${data.aws_ssm_parameter.database_username.value}"
    DB_PASSWORD = "${data.aws_ssm_parameter.database_password.value}"
  }
}

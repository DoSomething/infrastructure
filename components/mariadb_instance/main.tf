# Data resources:
data "aws_ssm_parameter" "database_username" {
  name = "/${var.name}/rds/username"
}

locals {
  # Should backups be enabled, and if so for how long? We keep backups for
  # the maximum window (30 days) on production, and otherwise the minimum
  # amount in order to satisfy functionality.
  base_backup_retention = var.is_dms_source ? 1 : 0

  backup_retention = var.environment == "production" ? 30 : local.base_backup_retention

  # The name of the database instance, in snake_case.
  safe_name = replace(coalesce(var.database_name, var.name), "-", "_")
}

resource "aws_db_parameter_group" "replication_settings" {
  count = var.is_dms_source ? 1 : 0

  name   = var.name
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

  tags = {
    Application = var.name
    Environment = var.environment
    Stack       = var.stack
  }
}

resource "random_string" "master_password" {
  length = 32

  # We can't use '@' or '$' in MySQL passwords.
  override_special = "!#%&*()-_=+[]{}<>:?"
}

resource "aws_db_instance" "database" {
  identifier = var.name
  name       = local.safe_name

  engine            = "mariadb"
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  multi_az          = var.multi_az

  parameter_group_name = coalesce(
    join("", aws_db_parameter_group.replication_settings.*.id),
    "default.mariadb10.3",
  )

  allow_major_version_upgrade = true

  backup_retention_period = local.backup_retention # See above!
  backup_window           = "06:00-07:00"          # 1-2am ET.

  enabled_cloudwatch_logs_exports = ["error", "slowquery"]

  username = data.aws_ssm_parameter.database_username.value
  password = random_string.master_password.result

  # TODO: We should migrate our account out of EC2-Classic, create
  # a default VPC, and let resources be created in there by default!
  db_subnet_group_name = var.subnet_group

  vpc_security_group_ids = var.security_groups
  publicly_accessible    = true

  deletion_protection = false == var.deprecated

  final_snapshot_identifier = "final-snapshot-${var.name}"

  tags = {
    Application = var.name
    Environment = var.environment
    Stack       = var.stack
  }
}

# Configure a MySQL provider for this instance.
provider "mysql" {
  version  = "~> 1.6"
  endpoint = aws_db_instance.database.endpoint
  username = aws_db_instance.database.username
  password = aws_db_instance.database.password
}

resource "random_string" "app_password" {
  length = 32

  # We can't use '@' or '$' in MySQL passwords.
  override_special = "!#%&*()-_=+[]{}<>:?"
}

resource "mysql_user" "app" {
  count              = var.deprecated ? 0 : 1
  user               = local.safe_name
  host               = "%"
  plaintext_password = random_string.app_password.result
}

resource "mysql_grant" "app" {
  count    = var.deprecated ? 0 : 1
  user     = mysql_user.app[0].user
  host     = mysql_user.app[0].host
  database = aws_db_instance.database.name

  # Grant minimum privileges necessary for table usage & running migrations.
  privileges = ["ALTER", "CREATE", "DELETE", "DROP", "INDEX", "INSERT", "SELECT", "UPDATE"]
}

resource "random_string" "readonly_password" {
  length = 24

  # We can't use '@' or '$' in MySQL passwords.
  override_special = "!#%&*()-_=+[]{}<>:?"
}

resource "mysql_user" "readonly" {
  count              = var.deprecated ? 0 : 1
  user               = "readonly"
  host               = "%"
  plaintext_password = random_string.readonly_password.result
}

resource "mysql_grant" "readonly" {
  count      = var.deprecated ? 0 : 1
  user       = mysql_user.readonly[0].user
  host       = mysql_user.readonly[0].host
  database   = aws_db_instance.database.name
  privileges = ["SELECT"]
}

resource "random_string" "fivetran_password" {
  length = 24

  # We can't use '@' or '$' in MySQL passwords.
  override_special = "!#%&*()-_=+[]{}<>:?"
}

resource "mysql_user" "fivetran" {
  count              = var.deprecated ? 0 : 1
  user               = "fivetran"
  host               = "%"
  plaintext_password = random_string.fivetran_password.result
}

resource "mysql_grant" "fivetran_select" {
  count      = var.deprecated ? 0 : 1
  user       = mysql_user.fivetran[0].user
  host       = mysql_user.fivetran[0].host
  database   = aws_db_instance.database.name
  privileges = ["SELECT"]
}

resource "mysql_grant" "fivetran_replication" {
  count      = var.deprecated ? 0 : 1
  user       = mysql_user.fivetran[0].user
  host       = mysql_user.fivetran[0].host
  database   = "*"
  privileges = ["REPLICATION CLIENT", "REPLICATION SLAVE"]
}
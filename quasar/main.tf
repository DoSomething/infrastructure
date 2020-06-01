terraform {
  backend "remote" {
    organization = "dosomething"

    workspaces {
      name = "quasar"
    }
  }
}

provider "aws" {
  version = "2.30.0"
  region  = "us-east-1"
  profile = "terraform"
}

provider "template" {
  version = "~> 2.1"
}

provider "random" {
  version = "~> 2.0"
}

# Our Slack Lookerbot instance needs access to an S3 bucket to publish
# visualizations.
module "lookerbot" {
  source = "../applications/lookerbot"

  name = "dosomething-lookerbot"
}

resource "aws_db_parameter_group" "quasar-qa-pg11" {
  name   = "quasar-qa-pg11"
  family = "postgres11"

  # Required for DMS CDC Replication:
  # https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.PostgreSQL.html#CHAP_Source.PostgreSQL.v10
  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }

  # Required for DMS CDC Replication:
  # https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.PostgreSQL.html#CHAP_Source.PostgreSQL.v10
  parameter {
    name         = "max_logical_replication_workers"
    value        = "500"
    apply_method = "pending-reboot"
  }

  # Recommended by PGTuner tool: https://pgtune.leopard.in.ua/#/
  # Sets effective RAM available to PG Query planner before using disk.
  parameter {
    name  = "effective_cache_size"
    value = "12000000"
  }

  # Recommended by PGTuner tool: https://pgtune.leopard.in.ua/#/
  # Amount of RAM available for cleanup tasks like vacuum, reindex, etc.
  parameter {
    name  = "maintenance_work_mem"
    value = "2000000"
  }

  # Recommended by PGTuner tool: https://pgtune.leopard.in.ua/#/
  # Amount of RAM available for joins/sort queries per connection.
  # Based on 50 connections.
  parameter {
    name  = "work_mem"
    value = "41943"
  }

  # Recommended to only allow SSL connections from clients.
  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  # Only log queries with a duration longer than this to get slow queries.
  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  # Only log slow queries.
  parameter {
    name  = "log_statement"
    value = "none"
  }

  parameter {
    name  = "log_duration"
    value = "0"
  }

  # Testing turning synchronization off to see if improves performance
  parameter {
    name  = "synchronous_commit"
    value = "off"
  }

  # Enabling for PG Badger query tuning analysis.
  parameter {
    name  = "log_connections"
    value = "1"
  }

  # Enabling for PG Badger query tuning analysis.
  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  # Enabling for PG Badger query tuning analysis.
  parameter {
    name  = "log_lock_waits"
    value = "1"
  }

  # Enabling for PG Badger query tuning analysis.
  parameter {
    name  = "log_temp_files"
    value = "0"
  }

  # Enabling for PG Badger query tuning analysis.
  parameter {
    name  = "log_autovacuum_min_duration"
    value = "0"
  }
}

resource "aws_db_parameter_group" "quasar-qa-pg12" {
  name   = "quasar-qa-pg12"
  family = "postgres12"

  # Required for DMS CDC Replication:
  # https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.PostgreSQL.html#CHAP_Source.PostgreSQL.v10
  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }

  # Required for DMS CDC Replication:
  # https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.PostgreSQL.html#CHAP_Source.PostgreSQL.v10
  parameter {
    name         = "max_logical_replication_workers"
    value        = "500"
    apply_method = "pending-reboot"
  }

  # Recommended by PGTuner tool: https://pgtune.leopard.in.ua/#/
  # Sets effective RAM available to PG Query planner before using disk.
  parameter {
    name  = "effective_cache_size"
    value = 12 * 1000 * 1000 # 12GB
  }

  # Recommended by PGTuner tool: https://pgtune.leopard.in.ua/#/
  # Amount of RAM available for cleanup tasks like vacuum, reindex, etc.
  parameter {
    name  = "maintenance_work_mem"
    value = 2 * 1000 * 1000 # 2GB
  }

  # Recommended by PGTuner tool: https://pgtune.leopard.in.ua/#/
  # Amount of RAM available for joins/sort queries per connection.
  parameter {
    name  = "work_mem"
    value = "26214"
  }

  # Recommended to only allow SSL connections from clients.
  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  # Only log queries with a duration longer than this to get slow queries.
  parameter {
    name  = "log_min_duration_statement"
    value = "1000" # 1 second, measured in milliseconds
  }

  # Only log slow queries.
  parameter {
    name  = "log_statement"
    value = "none"
  }

  parameter {
    name  = "log_duration"
    value = "0"
  }

  # Enabling for PG Badger query tuning analysis.
  parameter {
    name  = "log_connections"
    value = "1"
  }

  # Enabling for PG Badger query tuning analysis.
  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  # Enabling for PG Badger query tuning analysis.
  parameter {
    name  = "log_lock_waits"
    value = "1"
  }

  # Enabling for PG Badger query tuning analysis.
  parameter {
    name  = "log_temp_files"
    value = "0"
  }

  # Enabling for PG Badger query tuning analysis.
  parameter {
    name  = "log_autovacuum_min_duration"
    value = "0"
  }
}

resource "aws_db_parameter_group" "quasar-prod-pg11" {
  name   = "quasar-prod-pg11"
  family = "postgres11"

  # Required for DMS CDC Replication:
  # https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.PostgreSQL.html#CHAP_Source.PostgreSQL.v10
  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }

  # Required for DMS CDC Replication:
  # https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.PostgreSQL.html#CHAP_Source.PostgreSQL.v10
  parameter {
    name         = "max_logical_replication_workers"
    value        = "500"
    apply_method = "pending-reboot"
  }

  # Recommended by PGTuner tool: https://pgtune.leopard.in.ua/#/
  # Sets effective RAM available to PG Query planner before using disk.
  parameter {
    name  = "effective_cache_size"
    value = "48000000"
  }

  # Recommended by PGTuner tool: https://pgtune.leopard.in.ua/#/
  # Amount of RAM available for cleanup tasks like vacuum, reindex, etc.
  parameter {
    name  = "maintenance_work_mem"
    value = "2000000"
  }

  # Updated to match Heroku Premium-5 config which we experienced
  # as more performant when our data warehouse was hosted there.
  # Amount of RAM available for joins/sort queries per connection.
  parameter {
    name  = "work_mem"
    value = "120000"
  }

  # Recommended to only allow SSL connections from clients.
  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  # Only log queries with a duration longer than this to get slow queries.
  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  # Temporarily only log slow queries.
  parameter {
    name  = "log_statement"
    value = "none"
  }

  parameter {
    name  = "log_duration"
    value = "0"
  }

  # Set to default value globally per https://git.io/fjghW.
  parameter {
    name  = "statement_timeout"
    value = "0"
  }

  # Enabling for PG Badger query tuning analysis.
  parameter {
    name  = "log_connections"
    value = "1"
  }

  # Enabling for PG Badger query tuning analysis.
  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  # Enabling for PG Badger query tuning analysis.
  parameter {
    name  = "log_lock_waits"
    value = "1"
  }

  # Enabling for PG Badger query tuning analysis.
  parameter {
    name  = "log_temp_files"
    value = "0"
  }

  # Enabling for PG Badger query tuning analysis.
  parameter {
    name  = "log_autovacuum_min_duration"
    value = "0"
  }
}

data "aws_ssm_parameter" "qa_username" {
  name = "/quasar-qa/rds/username"
}

data "aws_ssm_parameter" "qa_password" {
  name = "/quasar-qa/rds/password"
}

data "aws_ssm_parameter" "prod_username" {
  name = "/quasar-prod/rds/username"
}

data "aws_ssm_parameter" "prod_password" {
  name = "/quasar-prod/rds/password"
}

# Trying to setup network resources necessary to remove existing
# longform value above from components/vpc module.

variable "rds_sec_group" {
  description = "Security group for Quasar RDS instances."
}

module "network" {
  source = "../components/vpc"

  rds_sec_group = module.aws_security_group.rds.id
}

resource "aws_db_instance" "quasar-qa" {
  allocated_storage               = 4000
  engine                          = "postgres"
  engine_version                  = "11.6"
  instance_class                  = "db.m5.xlarge"
  allow_major_version_upgrade     = true
  name                            = "quasar"
  username                        = data.aws_ssm_parameter.qa_username.value
  password                        = data.aws_ssm_parameter.qa_password.value
  parameter_group_name            = aws_db_parameter_group.quasar-qa-pg11.id
  vpc_security_group_ids          = var.rds_sec_group
  deletion_protection             = true
  storage_encrypted               = true
  copy_tags_to_snapshot           = true
  monitoring_interval             = "10"
  publicly_accessible             = true
  performance_insights_enabled    = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
}

resource "aws_db_instance" "quasar" {
  allocated_storage               = 4000
  engine                          = "postgres"
  engine_version                  = "11.4"
  instance_class                  = "db.m5.4xlarge"
  name                            = "quasar_prod_warehouse"
  username                        = data.aws_ssm_parameter.prod_username.value
  password                        = data.aws_ssm_parameter.prod_password.value
  parameter_group_name            = aws_db_parameter_group.quasar-prod-pg11.id
  vpc_security_group_ids          = var.rds_sec_group
  deletion_protection             = true
  storage_encrypted               = true
  copy_tags_to_snapshot           = true
  monitoring_interval             = "10"
  publicly_accessible             = true
  performance_insights_enabled    = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
}


# Provide S3 Bucket for Customer.io data file exports.

locals {
  cio_export = "quasar-cio"
}

module "iam_user" {
  source = "../components/iam_app_user"
  name   = local.cio_export
}

module "storage" {
  source = "../components/s3_bucket"

  name       = local.cio_export
  user       = module.iam_user.name
  acl        = "private"
  versioning = true
}

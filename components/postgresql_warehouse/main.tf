variable "database_name" {
  description = "The name used for this database."
}

variable "parameter_group_name" {
  description = "The name used for this database's parameter group."
}

variable "allocated_storage" {
  description = "The amount of storage (in GB) to allocate for this instance."
}

variable "instance_class" {
  description = "The RDS instance type for this database."
}

variable "username" {
  description = "The master username for the RDS PostgreSQL instance."
}

variable "password" {
  description = "The master password for the RDS PostgreSQL instance."
}

variable "effective_cache_size" {
  description = "Effective RAM available to PG Query planner before using disk."
}

variable "maintenance_work_mem" {
  description = "Amount of RAM available for cleanup tasks like vacuum, reindex, etc."
}

variable "work_mem" {
  description = "Amount of RAM available for joins/sort queries per connection."
}

variable "vpc_security_group_ids" {
  description = "The VPC security group IDs to grant access to this database."
}

resource "aws_db_parameter_group" "pg11" {
  name   = var.parameter_group_name
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
  # TODO: It'd be great to make this value dynamic by accessing RAM from
  # instance type var and having something like (rds.ram_value * .75) * 1000 * 1000. 
  parameter {
    name  = "effective_cache_size"
    value = var.effective_cache_size
  }

  # Recommended by PGTuner tool: https://pgtune.leopard.in.ua/#/
  # Amount of RAM available for cleanup tasks like vacuum, reindex, etc.
  # TODO: It'd be great to make this value dynamic by accessing RAM from
  # instance type var and having something like (rds.ram_value * .125) * 1000 * 1000. 
  parameter {
    name  = "maintenance_work_mem"
    value = var.maintenance_work_mem
  }

  # Recommended by PGTuner tool: https://pgtune.leopard.in.ua/#/
  # Amount of RAM available for joins/sort queries per connection.
  # Based on 50 connections.
  # TODO: Not sure we can dynamically generate this, but maybe set a default
  # value and override per QA/Prod environment. 
  parameter {
    name  = "work_mem"
    value = var.work_mem
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

  parameter {
    apply_method = "immediate"
    name         = "statement_timeout"
    value        = "0"
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

resource "aws_db_instance" "quasar" {
  allocated_storage               = var.allocated_storage
  engine                          = "postgres"
  engine_version                  = "11.4"
  allow_major_version_upgrade     = true
  instance_class                  = var.instance_class
  name                            = var.database_name
  username                        = var.username
  password                        = var.password
  parameter_group_name            = aws_db_parameter_group.pg11.id
  vpc_security_group_ids          = var.vpc_security_group_ids
  deletion_protection             = true
  storage_encrypted               = true
  copy_tags_to_snapshot           = true
  monitoring_interval             = "10"
  publicly_accessible             = true
  performance_insights_enabled    = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
}

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
  # TODO: It'd be great to make this value dynamic by accessing RAM from
  # instance type var and having something like (rds.ram_value * .75) * 1000 * 1000. 
  parameter {
    name  = "effective_cache_size"
    value = 12 * 1000 * 1000 # 12GB
  }

  # Recommended by PGTuner tool: https://pgtune.leopard.in.ua/#/
  # Amount of RAM available for cleanup tasks like vacuum, reindex, etc.
  # TODO: It'd be great to make this value dynamic by accessing RAM from
  # instance type var and having something like (rds.ram_value * .125) * 1000 * 1000. 
  parameter {
    name  = "maintenance_work_mem"
    value = 2 * 1000 * 1000 # 2GB
  }

  # Recommended by PGTuner tool: https://pgtune.leopard.in.ua/#/
  # Amount of RAM available for joins/sort queries per connection.
  # Based on 50 connections.
  # TODO: Not sure we can dynamically generate this, but maybe set a default
  # value and override per QA/Prod environment. 
  parameter {
    name  = "work_mem"
    value = "41943" # 42MB
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
  # TODO: It'd be great to make this value dynamic by accessing RAM from
  # instance type var and having something like (rds.ram_value * .75) * 1000 * 1000. 
  parameter {
    name  = "effective_cache_size"
    value = 12 * 1000 * 1000 # 12GB
  }

  # Recommended by PGTuner tool: https://pgtune.leopard.in.ua/#/
  # Amount of RAM available for cleanup tasks like vacuum, reindex, etc.
  # TODO: It'd be great to make this value dynamic by accessing RAM from
  # instance type var and having something like (rds.ram_value * .125) * 1000 * 1000. 
  parameter {
    name  = "maintenance_work_mem"
    value = 2 * 1000 * 1000 # 2GB
  }

  # Recommended by PGTuner tool: https://pgtune.leopard.in.ua/#/
  # Amount of RAM available for joins/sort queries per connection.
  # TODO: Not sure we can dynamically generate this, but maybe set a default
  # value and override per QA/Prod environment. 
  parameter {
    name  = "work_mem"
    value = "26214" # 26MB
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
  # TODO: It'd be great to make this value dynamic by accessing RAM from
  # instance type var and having something like (rds.ram_value * .75) * 1000 * 1000. 
  parameter {
    name  = "effective_cache_size"
    value = 48 * 1000 * 1000 #48GB
  }

  # Recommended by PGTuner tool: https://pgtune.leopard.in.ua/#/
  # Amount of RAM available for cleanup tasks like vacuum, reindex, etc.
  # TODO: It'd be great to make this value dynamic by accessing RAM from
  # instance type var and having something like (rds.ram_value * .125) * 1000 * 1000. 
  parameter {
    name  = "maintenance_work_mem"
    value = 2 * 1000 * 1000 # 2GB
  }

  # Updated to match Heroku Premium-5 config which we experienced
  # as more performant when our data warehouse was hosted there.
  # Amount of RAM available for joins/sort queries per connection.
  # TODO: Not sure we can dynamically generate this, but maybe set a default
  # value and override per QA/Prod environment. 
  parameter {
    name  = "work_mem"
    value = 120 * 1000 # 120MB
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

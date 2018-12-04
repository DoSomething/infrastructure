resource "aws_vpc" "vpc" {
  cidr_block = "10.255.0.0/16"

  tags {
    Name = "Quasar"
  }
}

resource "aws_subnet" "subnet-a" {
  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = "10.255.100.0/24"

  tags {
    Name = "Quasar RDS - 1A"
  }
}

resource "aws_subnet" "subnet-b" {
  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = "10.255.101.0/24"

  tags {
    Name = "Quasar RDS - 1E"
  }
}

resource "aws_security_group" "bastion" {
  name        = "Quasar-Bastion"
  description = "22 from Everywhere"
  vpc_id      = "${aws_vpc.vpc.id}"

  tags {
    Name = "Quasar-Bastion"
  }
}

resource "aws_security_group_rule" "bastion" {
  security_group_id = "${aws_security_group.bastion.id}"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "bastion-egress" {
  security_group_id = "${aws_security_group.bastion.id}"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"                               # All protocols.
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "jenkins" {
  name        = "Quasar-Jenkins"
  description = "22 from Quasar-Bastion, 8080 from Quasar-HA-Proxy"
  vpc_id      = "${aws_vpc.vpc.id}"

  tags {
    Name = "Quasar-Jenkins"
  }
}

resource "aws_security_group_rule" "jenkins-bastion" {
  security_group_id        = "${aws_security_group.jenkins.id}"
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.bastion.id}"
}

resource "aws_security_group_rule" "jenkins-haproxy" {
  security_group_id        = "${aws_security_group.jenkins.id}"
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.haproxy.id}"
}

resource "aws_security_group_rule" "jenkins-egress" {
  security_group_id = "${aws_security_group.jenkins.id}"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"                               # All protocols.
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "haproxy" {
  name        = "Quasar-HA-Proxy"
  description = "80/443 Everywhere, 22 from Quasar Bastion"
  vpc_id      = "${aws_vpc.vpc.id}"

  tags {
    Name = "Quasar-HA-Proxy"
  }
}

resource "aws_security_group_rule" "haproxy-http" {
  security_group_id = "${aws_security_group.haproxy.id}"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "haproxy-https" {
  security_group_id = "${aws_security_group.haproxy.id}"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "haproxy-bastion" {
  security_group_id        = "${aws_security_group.haproxy.id}"
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.bastion.id}"
}

resource "aws_security_group_rule" "haproxy-egress" {
  security_group_id = "${aws_security_group.haproxy.id}"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"                               # All protocols.
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "etl" {
  name        = "Quasar-ETL"
  description = "22 from Quasar-Bastion and Quasar-Jenkins"
  vpc_id      = "${aws_vpc.vpc.id}"

  tags {
    Name = "Quasar-ETL"
  }
}

resource "aws_security_group_rule" "etl-bastion" {
  security_group_id        = "${aws_security_group.etl.id}"
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.bastion.id}"
}

resource "aws_security_group_rule" "etl-jenkins" {
  security_group_id        = "${aws_security_group.etl.id}"
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.jenkins.id}"
}

resource "aws_security_group_rule" "etl-egress" {
  security_group_id = "${aws_security_group.etl.id}"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"                           # All protocols.
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "rds" {
  name        = "Quasar-PostgreSQL"
  description = "Quasar PostgreSQL Connectivity"
  vpc_id      = "${aws_vpc.vpc.id}"

  tags {
    Name = "Quasar-RDS"
  }
}

resource "aws_security_group_rule" "rds" {
  security_group_id = "${aws_security_group.rds.id}"
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "rds-etl" {
  security_group_id        = "${aws_security_group.rds.id}"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.etl.id}"
}

resource "aws_security_group_rule" "rds-egress" {
  security_group_id = "${aws_security_group.rds.id}"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"                           # All protocols.
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_db_parameter_group" "quasar-qa" {
  name   = "quasar-qa"
  family = "postgres10"

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
    value = "24000000"
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
    value = "20971"
  }
}

resource "aws_db_parameter_group" "quasar-prod" {
  name   = "quasar-prod"
  family = "postgres10"

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

  # Recommended by PGTuner tool: https://pgtune.leopard.in.ua/#/
  # Amount of RAM available for joins/sort queries per connection.
  # Based on 55 connections.
  parameter {
    name  = "work_mem"
    value = "19065"
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

resource "aws_db_instance" "quasar-qa" {
  allocated_storage      = 1000
  engine                 = "postgres"
  engine_version         = "10.5"
  instance_class         = "db.m5.2xlarge"
  name                   = "quasar"
  username               = "${data.aws_ssm_parameter.qa_username.value}"
  password               = "${data.aws_ssm_parameter.qa_password.value}"
  parameter_group_name   = "${aws_db_parameter_group.quasar-qa.id}"
  vpc_security_group_ids = ["${aws_security_group.rds.id}"]
  deletion_protection    = true
  storage_encrypted      = true
  copy_tags_to_snapshot  = true
  monitoring_interval    = "60"
  publicly_accessible    = true
}

resource "aws_db_instance" "quasar" {
  allocated_storage      = 4000
  engine                 = "postgres"
  engine_version         = "10.5"
  instance_class         = "db.m5.4xlarge"
  name                   = "quasar_prod_warehouse"
  username               = "${data.aws_ssm_parameter.prod_username.value}"
  password               = "${data.aws_ssm_parameter.prod_password.value}"
  parameter_group_name   = "${aws_db_parameter_group.quasar-prod.id}"
  vpc_security_group_ids = ["${aws_security_group.rds.id}"]
  deletion_protection    = true
  storage_encrypted      = true
  copy_tags_to_snapshot  = true
  monitoring_interval    = "60"
  publicly_accessible    = true
}

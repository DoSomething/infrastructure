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
# longform values above and source from components/vpc module.
variable "rds_sec_group" {
  description = "Security group for Quasar RDS instances."
}

module "network" {
  source = "../components/vpc"

  rds_sec_group = module.aws_security_group.rds.id
}

# Trying to setup parameter groups necessry to remove existing 
# longform values above and source from components/postgresql_instance module.

variable "qa_param_group" {
  description = "PostgreSQL parameter group for Quasar QA RDS Instance."
}

variable "prod_param_group" {
  description = "PostgreSQL parameter group for Quasar Prod RDS Instance."
}

module "parameters" {
  source = "../components/postgresql_instance"

  qa_param_group   = module.aws_db_parameter_group.quasar-qa-pg11.id
  prod_param_group = module.aws_db_parameter_group.quasar-prod-pg11.id
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
  parameter_group_name            = var.qa_param_group
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
  parameter_group_name            = var.prod_param_group
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

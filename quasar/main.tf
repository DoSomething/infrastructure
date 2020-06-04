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
module "vpc" {
  source = "../components/quasar_vpc"
}

# Trying to setup parameter groups necessry to remove existing 
# longform values above and source from components/postgresql_instance module.
module "warehouse" {
  source = "../components/postgresql_warehouse"

  database_name        = "quasar_prod_warehouse"
  parameter_group_name = "quasar-prod-pg11"
  instance_class       = "db.m5.4xlarge"
  engine_version       = "11.4"

  allocated_storage    = 4000
  effective_cache_size = 48 * 1000 * 1000 #48GB
  maintenance_work_mem = 2 * 1000 * 1000  # 2GB
  work_mem             = 120 * 1000       # 120MB

  username               = data.aws_ssm_parameter.prod_username.value
  password               = data.aws_ssm_parameter.prod_password.value
  vpc_security_group_ids = [module.vpc.rds_security_group.id]
}

module "warehouse-qa" {
  source = "../components/postgresql_warehouse"

  database_name        = "quasar" # TODO: This is misleading!
  parameter_group_name = "quasar-qa-pg11"
  instance_class       = "db.m5.xlarge"
  engine_version       = "11.6"

  allocated_storage    = 4000
  effective_cache_size = 12 * 1000 * 1000 # 12GB
  maintenance_work_mem = 2 * 1000 * 1000  # 2GB
  work_mem             = 41943            # 42MB

  username               = data.aws_ssm_parameter.qa_username.value
  password               = data.aws_ssm_parameter.qa_password.value
  vpc_security_group_ids = [module.vpc.rds_security_group.id]
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
  versioning = true
  private    = true
}

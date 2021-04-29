variable "heroku_email" {}
variable "heroku_api_key" {}

terraform {
  backend "remote" {
    organization = "dosomething"

    workspaces {
      name = "shared"
    }
  }
}

provider "aws" {
  version = "2.30.0"
  region  = "us-east-1"
  profile = "terraform"
}

provider "heroku" {
  version = "2.2.0"
  email   = var.heroku_email
  api_key = var.heroku_api_key
}

data "aws_caller_identity" "current" {}

data "aws_kms_alias" "default" {
  name = "alias/aws/ssm"
}

# This is the IAM user & access key that grants CircleCI the ability
# to read any secrets stored in the `/circleci/...` prefix in SSM.
resource "aws_iam_user" "circleci" {
  name = "circleci"
}

resource "aws_iam_user_policy" "circleci_policy" {
  user   = "${aws_iam_user.circleci.name}"
  policy = "${data.template_file.circleci_policy.rendered}"
}

data "template_file" "circleci_policy" {
  template = "${file("${path.module}/circleci-policy.json.tpl")}"

  vars = {
    kms_arn    = "${data.aws_kms_alias.default.arn}"
    account_id = "${data.aws_caller_identity.current.account_id}"
  }
}

resource "aws_iam_access_key" "circleci_key" {
  user = "${aws_iam_user.circleci.name}"
}

# Heroku pipelines
resource "heroku_pipeline" "northstar" {
  name = "northstar"
}

resource "heroku_pipeline" "phoenix" {
  name = "phoenix"
}

output "northstar_pipeline" {
  value = "${heroku_pipeline.northstar.id}"
}

output "phoenix_pipeline" {
  value = "${heroku_pipeline.phoenix.id}"
}

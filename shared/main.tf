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

  vars {
    kms_arn    = "${data.aws_kms_alias.default.arn}"
    account_id = "${data.aws_caller_identity.current.account_id}"
  }
}

resource "aws_iam_access_key" "circleci_key" {
  user = "${aws_iam_user.circleci.name}"
}

# Heroku pipelines
resource "heroku_pipeline" "graphql" {
  name = "graphql"
}

resource "heroku_pipeline" "northstar" {
  name = "northstar"
}

resource "heroku_pipeline" "rogue" {
  name = "rogue"
}

resource "heroku_pipeline" "phoenix" {
  name = "phoenix"
}

output "graphql_pipeline" {
  value = "${heroku_pipeline.graphql.id}"
}

output "northstar_pipeline" {
  value = "${heroku_pipeline.northstar.id}"
}

output "rogue_pipeline" {
  value = "${heroku_pipeline.rogue.id}"
}

output "phoenix_pipeline" {
  value = "${heroku_pipeline.phoenix.id}"
}

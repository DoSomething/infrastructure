# Experimental: This module builds a serverless GraphQL instance.

variable "environment" {
  description = "The environment for this application: development, qa, or production."
}

variable "name" {
  description = "The application name."
}

variable "papertrail_destination" {
  description = "The Papertrail log destination for this application."
}

data "aws_ssm_parameter" "contentful_gambit_space_id" {
  # All environments of this application use the same space.
  name = "/contentful/gambit/space-id"
}

data "aws_ssm_parameter" "contentful_api_key" {
  name = "/${var.name}/contentful/gambit/content-api-key"
}

data "aws_ssm_parameter" "northstar_auth_secret" {
  name = "/northstar/${var.environment}/clients/${var.name}"
}

data "aws_ssm_parameter" "gambit_username" {
  name = "/gambit/${local.gambit_env}/username"
}

data "aws_ssm_parameter" "gambit_password" {
  name = "/gambit/${local.gambit_env}/password"
}

data "aws_ssm_parameter" "apollo_engine_api_key" {
  name = "/${var.name}-lambda/apollo/api-key"
}

resource "random_string" "app_secret" {
  length = 32
}

locals {
  # Environment (e.g. 'dev' or 'DEV')
  env = "${var.environment == "development" ? "dev" : var.environment}"
  ENV = "${upper(local.env)}"

  # Gambit only has a production & QA environment:
  gambit_env = "${local.env == "dev" ? "qa" : local.env}"
}

module "app" {
  source = "../../shared/lambda_function"

  name        = "${var.name}"
  environment = "${var.environment}"

  config_vars = {
    APP_SECRET = "${random_string.app_secret.result}"

    # TODO: Update application to expect 'development' here.
    QUERY_ENV = "${local.env}"

    "${local.ENV}_NORTHSTAR_AUTH_ID"     = "${var.name}"
    "${local.ENV}_NORTHSTAR_AUTH_SECRET" = "${data.aws_ssm_parameter.northstar_auth_secret.value}"

    # TODO: Remove custom environment mapping once we have a 'dev' instance of Gambit Conversations.
    "${upper(local.gambit_env)}_GAMBIT_CONVERSATIONS_USER" = "${data.aws_ssm_parameter.gambit_username.value}"
    "${upper(local.gambit_env)}_GAMBIT_CONVERSATIONS_PASS" = "${data.aws_ssm_parameter.gambit_password.value}"

    GAMBIT_CONTENTFUL_SPACE_ID     = "${data.aws_ssm_parameter.contentful_gambit_space_id.value}"
    GAMBIT_CONTENTFUL_ACCESS_TOKEN = "${data.aws_ssm_parameter.contentful_api_key.value}"

    ENGINE_API_KEY = "${data.aws_ssm_parameter.apollo_engine_api_key.value}"
  }
}

resource "aws_dynamodb_table" "cache" {
  name         = "${var.name}-cache"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "segment"
  range_key = "id"

  attribute {
    name = "segment"
    type = "S"
  }

  attribute {
    name = "id"
    type = "S"
  }
}

data "template_file" "dynamodb_policy" {
  template = "${file("${path.module}/dynamodb-policy.json.tpl")}"

  vars {
    dynamodb_table_arn = "${aws_dynamodb_table.cache.arn}"
  }
}

resource "aws_iam_policy" "dynamodb_policy" {
  name = "${var.name}-dynamodb"
  path = "/"

  policy = "${data.template_file.dynamodb_policy.rendered}"
}

resource "aws_iam_role_policy_attachment" "dynamodb_policy" {
  role       = "${module.app.lambda_role}"
  policy_arn = "${aws_iam_policy.dynamodb_policy.arn}"
}

output "backend" {
  value = "${module.app.backend}"
}

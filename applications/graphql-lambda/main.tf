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

locals {
  safe_name = "${replace(var.name, "-", "_")}"
}

resource "aws_lambda_function" "function" {
  function_name = "${var.name}"
  handler       = "main.handler"

  s3_bucket = "${aws_s3_bucket.deploy.id}"
  s3_key    = "${aws_s3_bucket_object.build.key}"

  runtime = "nodejs8.10"

  role = "${aws_iam_role.lambda_exec.arn}"
}

resource "aws_s3_bucket" "deploy" {
  bucket = "${var.name}-deploy"
  acl    = "private"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_object" "build" {
  bucket = "${aws_s3_bucket.deploy.id}"
  key    = "${local.safe_name}.zip"
  source = "${path.module}/example.zip"
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/${aws_lambda_function.function.function_name}"
  retention_in_days = 14
}

# This is the "execution" role that is used to run this function:
resource "aws_iam_role" "lambda_exec" {
  name = "${var.name}"

  assume_role_policy = "${file("${path.module}/exec-policy.json")}"
}

resource "aws_iam_policy" "lambda_logging" {
  name = "${var.name}-logging"
  path = "/"

  policy = "${file("${path.module}/logging-policy.json")}"
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = "${aws_iam_role.lambda_exec.name}"
  policy_arn = "${aws_iam_policy.lambda_logging.arn}"
}

# This is the "deploy" role that is used to deploy new Lambda releases.
data "template_file" "deploy_policy" {
  template = "${file("${path.module}/deploy-policy.json.tpl")}"

  vars {
    deploy_bucket_arn = "${aws_s3_bucket.deploy.arn}"

    # TODO: Can we limit the IAM user to only deploying *this* function?
    # function_arn      = "${aws_lambda_function.function.arn}"
  }
}

resource "aws_iam_user" "lambda_deploy" {
  name = "${var.name}-deploy"
}

resource "aws_iam_user_policy" "deploy_policy" {
  user   = "${aws_iam_user.lambda_deploy.name}"
  policy = "${data.template_file.deploy_policy.rendered}"
}

resource "aws_iam_access_key" "deploy_key" {
  user = "${aws_iam_user.lambda_deploy.name}"
}

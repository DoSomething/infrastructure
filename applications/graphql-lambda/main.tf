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
  source = "${file("${path.module}/example.zip")}"
}

resource "aws_lambda_function" "function" {
  function_name = "${var.name}"
  handler       = "main.handler"

  s3_bucket = "${aws_s3_bucket.deploy.id}"
  s3_key    = "${aws_s3_bucket_object.build.key}"

  runtime = "nodejs8.10"

  role = "${aws_iam_role.lambda_exec.arn}"
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
# TODO: Y'know, add this thing!

resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/lambda/${aws_lambda_function.function.function_name}"
  retention_in_days = 14
}

# Experimental: This module builds a serverless Lambda function.

# Required variables:
variable "name" {
  description = "The application name."
}

variable "logger" {
  description = "The Lambda function ARN to subscribe to this function's log group."
  default     = ""
}

# Optional variables:
variable "config_vars" {
  description = "Environment variables for this application."
  default     = {}
}

variable "handler" {
  description = "The handler for this function."
  default     = "main.handler"
}

locals {
  safe_name = "${replace(var.name, "-", "_")}"
}

# The lambda function and API gateway:
resource "aws_lambda_function" "function" {
  function_name = "${var.name}"
  handler       = "${var.handler}"

  s3_bucket = "${aws_s3_bucket.deploy.id}"
  s3_key    = "${aws_s3_bucket_object.release.key}"

  runtime = "nodejs8.10"

  # We increase our function's memory allocation in order to
  # decrease worst-case cold start times. <https://git.io/fh1qE>
  memory_size = 512 # MB.

  # We set a "sane default" 15 second timeout (matching
  # our Fastly configs) to avoid runaway requests.
  timeout = 15

  environment {
    variables = "${var.config_vars}"
  }

  role = "${aws_iam_role.lambda_exec.arn}"
}

# Deploy artifacts:
resource "aws_s3_bucket" "deploy" {
  bucket = "${var.name}-deploy"
  acl    = "private"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_object" "release" {
  bucket = "${aws_s3_bucket.deploy.id}"
  key    = "release.zip"

  # We hard-code this module's path (from the root) here to avoid an issue
  # where ${path.module} marks this as "dirty" on different machines.
  source = "shared/lambda_function/example.zip"
}

# Log group:
resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/${aws_lambda_function.function.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_subscription_filter" "papertrail_subscription" {
  count = "${var.logger == "" ? 0 : 1}"

  name            = "papertrail_forwarder"
  log_group_name  = "${aws_cloudwatch_log_group.log_group.name}"
  destination_arn = "${var.logger}"

  # Forward all log messages:
  filter_pattern = ""
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  count = "${var.logger == "" ? 0 : 1}"

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${var.logger}"
  principal     = "logs.us-east-1.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.log_group.arn}"
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

resource "aws_iam_policy" "lambda_xray" {
  name = "${var.name}-xray"
  path = "/"

  policy = "${file("${path.module}/xray-policy.json")}"
}

resource "aws_iam_role_policy_attachment" "lambda_xray" {
  role       = "${aws_iam_role.lambda_exec.name}"
  policy_arn = "${aws_iam_policy.lambda_xray.arn}"
}

# This is the "deploy" role that is used to deploy new code:
resource "aws_iam_user" "lambda_deploy" {
  name = "${var.name}-deploy"
}

resource "aws_iam_user_policy" "deploy_policy" {
  user   = "${aws_iam_user.lambda_deploy.name}"
  policy = "${data.template_file.deploy_policy.rendered}"
}

data "template_file" "deploy_policy" {
  template = "${file("${path.module}/deploy-policy.json.tpl")}"

  vars {
    deploy_bucket_arn   = "${aws_s3_bucket.deploy.arn}"
    lambda_function_arn = "${aws_lambda_function.function.arn}"
  }
}

resource "aws_iam_access_key" "deploy_key" {
  user = "${aws_iam_user.lambda_deploy.name}"
}

resource "aws_ssm_parameter" "ssm_access_key" {
  name  = "/circleci/${var.name}/AWS_ACCESS_KEY_ID"
  type  = "SecureString"
  value = "${aws_iam_access_key.deploy_key.id}"
}

resource "aws_ssm_parameter" "ssm_secret_key" {
  name  = "/circleci/${var.name}/AWS_SECRET_ACCESS_KEY"
  type  = "SecureString"
  value = "${aws_iam_access_key.deploy_key.secret}"
}

output "name" {
  value = "${aws_lambda_function.function.function_name}"
}

output "arn" {
  value = "${aws_lambda_function.function.arn}"
}

output "invoke_arn" {
  value = "${aws_lambda_function.function.invoke_arn}"
}

output "lambda_role" {
  value = "${aws_iam_role.lambda_exec.name}"
}

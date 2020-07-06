# Experimental: This module builds a serverless Lambda function.

locals {
  safe_name = replace(var.name, "-", "_")
}

# The lambda function and API gateway:
resource "aws_lambda_function" "function" {
  function_name = var.name
  handler       = var.handler

  s3_bucket = aws_s3_bucket.deploy.id
  s3_key    = aws_s3_bucket_object.release.key

  runtime = var.runtime

  # We increase our function's memory allocation in order to
  # decrease worst-case cold start times. <https://git.io/fh1qE>
  memory_size = 512 # MB.

  # We set a "sane default" 15 second timeout (matching
  # our Fastly configs) to avoid runaway requests.
  timeout = 15

  environment {
    variables = var.config_vars
  }

  role = aws_iam_role.lambda_exec.arn

  tags = {
    Application = var.application
    Environment = var.environment
    Stack       = var.stack
  }
}

# Deploy artifacts:
resource "aws_s3_bucket" "deploy" {
  bucket = "${var.name}-deploy"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = {
    Application = var.application
    Environment = var.environment
    Stack       = var.stack
  }
}

resource "aws_s3_bucket_public_access_block" "private_policy" {
  bucket = aws_s3_bucket.deploy.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
}

resource "aws_s3_bucket_object" "release" {
  bucket = aws_s3_bucket.deploy.id
  key    = "release.zip"
  source = "${path.module}/default-${var.runtime}.zip"
}

# Log group:
resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/${aws_lambda_function.function.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_subscription_filter" "papertrail_subscription" {
  count = var.logger != null ? 1 : 0

  name            = "papertrail_forwarder"
  log_group_name  = aws_cloudwatch_log_group.log_group.name
  destination_arn = var.logger.arn
  distribution    = "ByLogStream"

  # Forward all log messages:
  filter_pattern = ""
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  count = var.logger != null ? 1 : 0

  action        = "lambda:InvokeFunction"
  function_name = var.logger.arn
  principal     = "logs.us-east-1.amazonaws.com"
  source_arn    = aws_cloudwatch_log_group.log_group.arn
}

# This is the "execution" role that is used to run this function:
resource "aws_iam_role" "lambda_exec" {
  name = var.name

  assume_role_policy = file("${path.module}/exec-policy.json")
}

resource "aws_iam_policy" "lambda_logging" {
  name = "${var.name}-logging"
  path = "/"

  policy = file("${path.module}/logging-policy.json")
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_policy" "lambda_xray" {
  name = "${var.name}-xray"
  path = "/"

  policy = file("${path.module}/xray-policy.json")
}

resource "aws_iam_role_policy_attachment" "lambda_xray" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_xray.arn
}

# This is the "deploy" role that is used to deploy new code:
resource "aws_iam_user" "lambda_deploy" {
  name = "${var.name}-deploy"
}

resource "aws_iam_user_policy" "deploy_policy" {
  user = aws_iam_user.lambda_deploy.name
  policy = templatefile("${path.module}/deploy-policy.json.tpl", {
    deploy_bucket_arn   = aws_s3_bucket.deploy.arn
    lambda_function_arn = aws_lambda_function.function.arn
  })
}

resource "aws_iam_access_key" "deploy_key" {
  user = aws_iam_user.lambda_deploy.name
}

resource "aws_ssm_parameter" "ssm_access_key" {
  name  = "/circleci/${var.name}/AWS_ACCESS_KEY_ID"
  type  = "SecureString"
  value = aws_iam_access_key.deploy_key.id
}

resource "aws_ssm_parameter" "ssm_secret_key" {
  name  = "/circleci/${var.name}/AWS_SECRET_ACCESS_KEY"
  type  = "SecureString"
  value = aws_iam_access_key.deploy_key.secret
}


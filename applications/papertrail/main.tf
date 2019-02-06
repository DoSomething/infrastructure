variable "environment" {
  description = "The environment for this application: development, qa, or production."
}

variable "name" {
  description = "The application name."
}

variable "papertrail_destination" {
  description = "The Papertrail log destination to forward to."
}

module "forwarder" {
  source = "../../shared/lambda_function"

  name        = "${var.name}"
  environment = "${var.environment}"

  config_vars = {
    PAPERTRAIL_HOST = "${element(split(":", var.papertrail_destination), 0)}"
    PAPERTRAIL_PORT = "${element(split(":", var.papertrail_destination), 1)}"
  }
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${module.forwarder.name}"
  principal     = "events.amazonaws.com"
  source_arn    = "arn:aws:events:eu-west-1:111122223333:rule/RunDaily"
  qualifier     = "${aws_lambda_alias.latest.name}"
}

resource "aws_lambda_alias" "latest" {
  name             = "latest"
  function_name    = "${module.forwarder.name}"
  function_version = "$LATEST"
}

output "arn" {
  value = "${module.forwarder.arn}"
}

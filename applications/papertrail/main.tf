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
  principal     = "logs.us-east-1.amazonaws.com"
}

output "arn" {
  value = "${module.forwarder.arn}"
}

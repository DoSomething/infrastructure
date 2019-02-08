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
  source = "../../components/lambda_function"

  name    = "${var.name}"
  runtime = "nodejs8.10"
  handler = "handler.log"

  config_vars = {
    PAPERTRAIL_HOST = "${element(split(":", var.papertrail_destination), 0)}"
    PAPERTRAIL_PORT = "${element(split(":", var.papertrail_destination), 1)}"
  }
}

output "arn" {
  value = "${module.forwarder.arn}"
}

# Required variables:
variable "name" {
  description = "The name for this queue (usually the application name)."
}

variable "user" {
  description = "The IAM user to grant permissions to read/write to this queue."
}

resource "aws_sqs_queue" "queue" {
  name                      = var.name
  message_retention_seconds = 60 * 60 * 24 * 14 # 14 days (maximum).
}

data "template_file" "sqs_policy" {
  template = file("${path.module}/iam-policy.json.tpl")

  vars = {
    queue_arn = aws_sqs_queue.queue.arn
  }
}

resource "aws_iam_user_policy" "sqs_policy" {
  name   = "${var.name}-sqs"
  user   = var.user
  policy = data.template_file.sqs_policy.rendered
}

output "id" {
  value = aws_sqs_queue.queue.id
}

output "config_vars" {
  value = {
    QUEUE_DRIVER      = "sqs"
    SQS_DEFAULT_QUEUE = aws_sqs_queue.queue.id
  }
}


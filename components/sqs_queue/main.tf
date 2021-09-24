resource "aws_sqs_queue" "queue" {
  name                      = var.name
  message_retention_seconds = 60 * 60 * 24 * 14 # 14 days (maximum).

  tags = {
    Application = var.application
    Environment = var.environment
    Stack       = var.stack
  }
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
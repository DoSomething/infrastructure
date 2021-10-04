output "id" {
  value = aws_sqs_queue.queue.id
}

output "config_vars" {
  value = {
    AWS_SQS_QUEUE    = aws_sqs_queue.queue.id
    QUEUE_CONNECTION = "sqs"

    # @TODO: Remove these old vars once safe to do so!
    QUEUE_DRIVER      = "sqs"
    SQS_DEFAULT_QUEUE = aws_sqs_queue.queue.id
  }
}
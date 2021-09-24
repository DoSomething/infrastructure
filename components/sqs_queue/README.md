# S3 Bucket

This module creates an [Amazon SQS](https://aws.amazon.com/sqs/) queue.

For all options, see the [variables](https://github.com/DoSomething/infrastructure/blob/main/components/sqs_queue/variables.tf) this module accepts & [outputs](https://github.com/DoSomething/infrastructure/blob/main/components/sqs_queue/outputs.tf) it generates.

### Usage

To create a new queue with default settings:

```hcl
module "queue" {
  source = "../../components/sqs_queue"

  application = var.name
  name        = var.name
  environment = var.environment
  stack       = var.stack

  user = module.iam_user.name
}
```

You can provide standard environment variables to your application via `module.queue.config_vars`.
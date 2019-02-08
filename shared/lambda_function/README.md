# Lambda Function

This module creates a Lambda function. It will also create a CloudWatch log group, IAM execution role, deployment S3 bucket, and limited deployment credentials for CircleCI.

For all options, see the [variables](#) this module accepts & [outputs](#) it generates.

> :wave: Check out the [Getting Started](https://github.com/DoSomething/infrastructure/blob/master/docs/serverless-guide.md) guide for a step-by-step walkthrough!

### Usage

```hcl
module "app" {
  source = "../shared/lambda_function"

  name = "hello-serverless"
  handler = "main.handler" # Run the 'handler' export from 'main.js'.
}
```

You can configure [Papertrail logging](https://github.com/DoSomething/communal-docs/blob/master/Monitoring/papertrail.md) by setting the `logger` variable (using one the `papertrail` module from `dosomething`, `dosomething-qa,` or `dosomething-dev`):

```hcl
module "app" {
  source = "../shared/lambda_function"

  name   = "hello-serverless"
  logger = "${module.papertrail.arn}"
}
```

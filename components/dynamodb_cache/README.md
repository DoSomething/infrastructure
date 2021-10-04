# DynamoDB Cache

This module creates a [DynamoDB](https://aws.amazon.com/dynamodb/) cache table schema. DynamoDB is Amazon's "serverless" key-value database, and allows us to easily scale our cache with usage.

For all options, see the [variables](https://github.com/DoSomething/infrastructure/blob/main/components/dynamodb_cache/variables.tf) this module accepts & [outputs](https://github.com/DoSomething/infrastructure/blob/main/components/dynamodb_cache/outputs.tf) it generates.

> :warning: It may be better to use the [dynamodb_policy](https://github.com/DoSomething/infrastructure/blob/main/components/dynamodb_policy/) module, which allows applications to manage their own table schemas.

### Usage

```hcl
module "cache" {
  source = "../../components/dynamodb_cache"

  application = var.name
  name        = "${var.name}-cache"
  environment = var.environment
  stack       = var.stack

  roles = [module.lambda_function.lambda_role]
}
```
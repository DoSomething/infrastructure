# DynamoDB Policy

This module grants an application access to tables in [DynamoDB](https://aws.amazon.com/dynamodb/). An application is allowed to create or update the schema for any tables prefixed by the same `${var.name}-`. For safety, applications cannot delete their tables.

For all options, see the [variables](https://github.com/DoSomething/infrastructure/blob/main/components/dynamodb_policy/variables.tf) this module accepts.

### Usage

This gives a Lambda function the ability to create, read, and write to tables prefixed with `dosomething-bertly-`.

```hcl
module "database" {
  source = "../components/dynamodb_policy"

  name  = "dosomething-bertly" 
  roles = [module.app.lambda_role]
}
```

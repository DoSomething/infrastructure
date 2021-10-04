# IAM Application User

This module creates an [IAM](https://aws.amazon.com/iam/) user and access key, which allows applications to access AWS resources.

For all options, see the [variables](https://github.com/DoSomething/infrastructure/blob/main/components/iam_app_user/variables.tf) this module accepts & [outputs](https://github.com/DoSomething/infrastructure/blob/main/components/iam_app_user/outputs.tf) it generates.

### Usage

To create a new IAM user for the given application:

```hcl
module "iam_user" {
  source = "../../components/iam_app_user"
  name   = var.name
}
```

You can then provide standard AWS environment variables to your application via `module.iam_user.config_vars`.
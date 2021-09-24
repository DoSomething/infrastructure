# S3 Bucket

This module creates an [Amazon S3](https://aws.amazon.com/s3/) object storage bucket.

For all options, see the [variables](https://github.com/DoSomething/infrastructure/blob/main/components/s3_bucket/variables.tf) this module accepts & [outputs](https://github.com/DoSomething/infrastructure/blob/main/components/s3_bucket/outputs.tf) it generates.

### Usage

To create a new storage bucket with default settings:

```hcl
module "storage" {
  source = "../../components/s3_bucket"

  application = var.name
  name        = var.storage_name
  environment = var.environment
  stack       = var.stack 
  user        = module.iam_user.name
}
```

You can provide standard environment variables to your application via `module.storage.config_vars`.
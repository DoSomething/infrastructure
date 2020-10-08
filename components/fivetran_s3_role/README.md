# Fivetran S3 Policy 

This module configures an IAM policy/role to allow [Fivetran](https://fivetran.com) to read the given S3 bucket. We use Fivetran to ingest data into our data warehouse for analysis.

For all options, see the [variables](https://github.com/DoSomething/infrastructure/blob/main/components/fivetran_s3_role/variables.tf) this module accepts & [outputs](https://github.com/DoSomething/infrastructure/blob/main/components/fivetran_s3_role/outputs.tf) it generates.

### Usage

```hcl
module "fivetran_role" {
  source = "../components/fivetran_s3_role"

  environment = "qa"
  name        = "dosomething-example"
  bucket      = module.storage.bucket
}
```
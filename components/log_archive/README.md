# Log Archive

This module creates a [Papertrail archive](https://www.papertrail.com/help/automatic-s3-archive-export/) bucket on [Amazon S3](https://aws.amazon.com/s3/).

For all options, see the [variables](https://github.com/DoSomething/infrastructure/blob/main/components/log_archive/variables.tf) this module accepts.

### Usage

To create a new Papertrail log bucket:

```hcl
module "log_archive" {
  source = "../components/log_archive"
  name   = "dosomething-papertrail"
}
```
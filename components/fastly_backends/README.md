# Fastly Backend

This module creates a [Fastly](http://fastly.com) CDN property for one or more backend applications. This handles caching, security headers, geolocation & logging.

For all options, see the [variables](https://github.com/DoSomething/infrastructure/blob/main/components/fastly_backends/variables.tf) this module accepts.

### Usage

This creates a Fastly property that handles traffic for the provided (Heroku) backend application:

```hcl
module "fastly-backend" {
  source = "../components/fastly_backends"
  name   = "Terraform: Backends"

  applications = [
    module.northstar,
  ]

  papertrail_destination = var.papertrail_destination_fastly
}
```

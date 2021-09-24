# Fastly Frontend

This module creates a [Fastly](http://fastly.com) CDN property for our [Phoenix](https://github.com/DoSomething/phoenix-next) frontend application. This handles redirects, caching, security headers, geolocation & logging.

For all options, see the [variables](https://github.com/DoSomething/infrastructure/blob/main/components/fastly_frontend/variables.tf) this module accepts.

### Redirects

URL redirects can be added or removed from this service's `redirects` dictionary via Fastly's [Edge Dictionary API](https://docs.fastly.com/en/guides/working-with-dictionaries-using-the-api).

We manage redirects for these services using the "Redirects" admin panel in Northstar's administrative interface.

### Usage

This creates a Fastly property that handles traffic for the provided (Heroku) backend application:

```hcl
module "fastly-frontend" {
  source = "../components/fastly_frontend"
  name   = "Terraform: Frontend"

  environment            = "production"
  application            = module.phoenix
  papertrail_destination = var.papertrail_destination_fastly
}
```

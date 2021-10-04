# Heroku Application

This module creates a [Heroku](http://heroku.com) application, which is our preferred hosting provider at DoSomething.org.

For all options, see the [variables](https://github.com/DoSomething/infrastructure/blob/main/components/heroku_app/variables.tf) this module accepts & [outputs](https://github.com/DoSomething/infrastructure/blob/main/components/heroku_app/outputs.tf) it generates.

### Usage

We currently support deploying [`laravel`](https://laravel.com) and [`express`](https://expressjs.com) frameworks. This will set the app's buildpack & default environment variables.

For example, to deploy a Laravel app to Heroku:

```hcl
module "app" {
  source = "../../components/heroku_app"

  framework   = "laravel"
  name        = var.name
  domain      = var.domain
  pipeline    = var.pipeline
  environment = var.environment

  config_vars = {
      CUSTOM_ENVIRONMENT_VARIABLE = "value"
  }
  
  web_scale = 2
  queue_scale = 1

  with_redis = true

  papertrail_destination = var.papertrail_destination
  with_newrelic          = var.environment == "production"
}
```

### Auto-scaling

If we're autoscaling this application (either with [Heroku Autoscaling](https://devcenter.heroku.com/articles/scaling#autoscaling) or [HireFire](https://www.hirefire.io)), use the `ignore_web = true` variable to ensure that Terraform does not try to override any autoscaling events.
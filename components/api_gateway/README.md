# API Gateway

This module creates an [API Gateway](https://aws.amazon.com/api-gateway/). It's used to expose Lambda functions over the internet. If you only have one Lambda function that responds to all requests, consider using the [`api_gateway_proxy`](https://github.com/DoSomething/infrastructure/blob/master/components/api_gateway_proxy/) module instead.

For all options, see the [variables](https://github.com/DoSomething/infrastructure/blob/master/components/api_gateway/variables.tf) this module accepts & [outputs](https://github.com/DoSomething/infrastructure/blob/master/components/api_gateway/outputs.tf) it generates.

> :wave: Check out the [Getting Started](https://github.com/DoSomething/infrastructure/blob/master/docs/serverless-guide.md) guide for a step-by-step walkthrough!

### Usage

```hcl
module "gateway" {
  source = "../components/api_gateway"

  name                = "hello-serverless"
  
  # The functions this gateway interacts with:
  functions           = ["${module.app.arn}"]

  # The root function (required) responds to `/` requests:
  root_function        = "${module.app.arn}"
  # root_method        = "ANY" (optional)
  # root_authorization = "NONE" (optional, set to 'CUSTOM' for custom authorizer)
  # root_authorizer_id = "${module.authorizer.invoke_arn}" (optional, if 'CUSTOM')

  # Any other routes can be defined in this list, with each route
  # expressed as a map of { path, function, method, authorization }
  routes = [
    {
      path            = "{proxy+}"
      function        = "${module.app.invoke_arn}"
      # method        = "ANY" (optional)
      # authorization = "NONE" (optional, set to 'CUSTOM' for custom authorizer)
      # authorizer_id = "${module.authorizer.invoke_arn}" (optional, if 'CUSTOM')
    },
  ]
}
```

You can configure [a custom domain](https://github.com/DoSomething/infrastructure/blob/master/docs/serverless-guide.md#bonus-add-a-custom-domain) by setting the `domain` variable. This will automatically configure a SSL certificate for DoSomething.org subdomains. If using another base domain (say, `dosome.click`), you'll need to first [add that domain to ACM & validate ownership](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request-public.html):

```hcl
module "gateway" {
  source = "../components/api_gateway"

  name                = "hello-serverless"
  functions           = ["${module.app.arn}"]
  root_function       = "${module.app.arn}"

  routes = [
    {
      path            = "{proxy+}"
      function        = "${module.app.invoke_arn}"
    },
  ]

  # The custom domain for this gateway:
  domain = "hello-serverless.dosomething.org"
}
```

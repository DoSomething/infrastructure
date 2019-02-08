# API Gateway (Proxy)

This module creates an [API Gateway](https://aws.amazon.com/api-gateway/). It's used to expose Lambda functions over the internet. At the moment, this module only supports using API Gateway as a "proxy" (so all requests to the given domain are forwarded to a single Lambda function, which handles routing internally).

For all options, see the [variables](https://github.com/DoSomething/infrastructure/blob/master/shared/api_gateway_proxy/variables.tf) this module accepts & [outputs](https://github.com/DoSomething/infrastructure/blob/master/shared/api_gateway_proxy/outputs.tf) it generates.

> :wave: Check out the [Getting Started](https://github.com/DoSomething/infrastructure/blob/master/docs/serverless-guide.md) guide for a step-by-step walkthrough!

### Usage

```hcl
module "gateway" {
  source = "shared/api_gateway_proxy"

  name                = "hello-serverless"
  environment         = "development"
  function_arn        = "${module.app.arn}"
  function_invoke_arn = "${module.app.invoke_arn}"
}
```

You can configure [a custom domain](https://github.com/DoSomething/infrastructure/blob/master/docs/serverless-guide.md#bonus-add-a-custom-domain) by setting the `domain` variable. This will automatically configure a SSL certificate for DoSomething.org subdomains. If using another base domain (say, `dosome.click`), you'll need to first [add that domain to ACM & validate ownership](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request-public.html):

```hcl
module "gateway" {
  source = "shared/api_gateway_proxy"

  name                = "hello-serverless"
  environment         = "development"
  function_arn        = "${module.app.arn}"
  function_invoke_arn = "${module.app.invoke_arn}"

  domain = "hello-serverless.dosomething.org"
}
```

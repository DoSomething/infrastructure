# API Gateway (Proxy)

This module creates an [API Gateway](https://aws.amazon.com/api-gateway/). It's used to expose Lambda functions over the internet. If you want to use this gateway with multiple Lambda functions, use the [`api_gateway`](https://github.com/DoSomething/infrastructure/blob/main/components/api_gateway/) module instead.

For all options, see the [variables](https://github.com/DoSomething/infrastructure/blob/main/components/api_gateway_proxy/variables.tf) this module accepts & [outputs](https://github.com/DoSomething/infrastructure/blob/main/components/api_gateway_proxy/outputs.tf) it generates.

> :wave: Check out the [Getting Started](https://github.com/DoSomething/infrastructure/blob/main/docs/serverless-guide.md) guide for a step-by-step walkthrough!

### Usage

```hcl
module "gateway" {
  source = "../components/api_gateway_proxy"

  name                = "hello-serverless"
  function_arn        = "${module.app.arn}"
  function_invoke_arn = "${module.app.invoke_arn}"
}
```

You can configure [a custom domain](https://github.com/DoSomething/infrastructure/blob/main/docs/serverless-guide.md#bonus-add-a-custom-domain) by setting the `domain` variable. This will automatically configure a SSL certificate for DoSomething.org subdomains. If using another base domain (say, `dosome.click`), you'll need to first [add that domain to ACM & validate ownership](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request-public.html):

```hcl
module "gateway" {
  source = "../components/api_gateway_proxy"

  name                = "hello-serverless"
  environment         = "development"
  function_arn        = "${module.app.arn}"
  function_invoke_arn = "${module.app.invoke_arn}"

  domain = "hello-serverless.dosomething.org"
}
```

# Serverless: Getting Started

**Serverless** backends like [AWS Lambda](https://aws.amazon.com/lambda/) allow us to write and run code without thinking about what server it is going to run on. Specifically, these technologies allow us to **automatically scale** based on traffic and only **pay for as much as we use**. It's great for applications where traffic is inconsistent.

> :bulb: We use "lower-case" serverless – the [architecture](https://martinfowler.com/articles/serverless.html), not [the name-brand framework](https://serverless.com). ([Why?](https://github.com/DoSomething/infrastructure/issues/129))

### Step 1: Creating our Function
We manage our serverless infrastructure with Terraform. To start, use the `lambda_function` module to provision a
new function. This will create a new function with the given name. It will also create a log group, execution role, deployment bucket, and limited deployment credentials.

```hcl
module "app" {
  source = "../shared/lambda_function"

  name    = "hello-serverless"
  runtime = "nodejs8.10"
}
```

After you run `make apply`, you should see the function on the [AWS Console](http://console.aws.amazon.com):

![AWS Lambda GUI](https://user-images.githubusercontent.com/583202/52375124-e4f99400-2a2c-11e9-832c-ec6e93b1cf27.png)

We haven't configured the function to accept HTTP requests yet (and not all Serverless functions have to). We can check that everything works by executing this function using the AWS CLI:

```
$ aws lambda invoke --function-name=hello-serverless /dev/stdout

{"statusCode":200,"headers":{"Content-Type":"text/html; charset=utf-8"},"body":"<p>Hello world!</p>"}{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}
```

We're off to a great start! :rocket:

### Step 2: Add HTTP Endpoints (optional)
Often, we'll want our functions to be accessible via the internet. To do so, let's add an [API Gateway](https://aws.amazon.com/api-gateway/):

**Note:** At the moment, we only "officially" support using API Gateway as a proxy.

```hcl
module "gateway" {
  source = "shared/api_gateway_proxy"

  name                = "hello-serverless"
  environment         = "development"
  function_arn        = "${module.app.arn}"
  function_invoke_arn = "${module.app.invoke_arn}"
}
```

If we apply that change and return to our Lambda dashboard, we'll see it now has a "API Gateway" trigger. Click on it to see the URL that's been automatically provisioned for this application:

<img width="1375" alt="Lambda dashboard with API Gateway trigger" src="https://user-images.githubusercontent.com/583202/52376426-1f186500-2a30-11e9-8548-c043988c530e.png">

If we visit that URL, anyone can now execute our "hello world" Lambda function via the web!

<img width="1375" alt="Hello World function over the web" src="https://user-images.githubusercontent.com/583202/52376506-4cfda980-2a30-11e9-904a-57663ab6abd8.png">

#### Bonus: Add a Custom Domain

To use a custom domain, just set the `domain` variable on the gateway:

```hcl
module "gateway" {
  # ...
  domain = "hello-serverless.dosomething.org"
}
```

This will attach the custom domain to our API Gateway, and (if it's a [DoSomething.org](https://www.dosomething.org) subdomain) automatically provision a SSL Certificate using [Amazon Certificate Manager](https://aws.amazon.com/certificate-manager/). If you're using a different top-level domain, you'll need to [manually request & validate a certificate](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request-public.html).

Once you've attached the custom domain, visit API Gateway's [Custom Domain Names](https://us-east-1.console.aws.amazon.com/apigateway/home?region=us-east-1#/custom-domain-names) panel to find out what CNAME to point the DNS record at. Ask someone in `#dev-infrastructure` to attach it to the domain in our [DNSMadeEasy](https://dnsmadeeasy.com/) account. You may have to wait **up to 40 minutes** for the certificate and [CloudFront](https://aws.amazon.com/cloudfront/) distribution to finish provisioning:

<img width="1375" alt="screen shot 2019-02-06 at 5 10 58 pm" src="https://user-images.githubusercontent.com/583202/52377319-7f100b00-2a32-11e9-8201-0e42790c09c3.png">

Your patience will be rewarded with a fancy new domain!

<img width="1375" alt="screen shot 2019-02-06 at 5 54 04 pm" src="https://user-images.githubusercontent.com/583202/52380110-77ecfb00-2a3a-11e9-9376-2029249dbf18.png">


### Step 3: Deploying Code
In rare cases, you may want more than the default "hello world" app can provide. Luckily, deploying code is a breeze.

We deploy our serverless applications using [CircleCI](https://circleci.com) and our [`dosomething/lambda`](https://circleci.com/orbs/registry/orb/dosomething/lambda) helper orb. If you haven't already, add a `.circleci/config.yml` file to your application's repository. You can use the template below to start, making sure to replace `hello-serverless` in the deploy step with the name of your Lambda function:

```yml
version: 2.1

orbs:
  lambda: dosomething/lambda@0.0.3

jobs:
  # Install dependencies, run tests, and compile for Lambda.
  build:
    docker:
      - image: circleci/node:8.10
    steps:
      - checkout
      - restore_cache:
          keys:
          - v1-dependencies-{{ checksum "package.json" }}
          - v1-dependencies-
      - run: npm install
      - save_cache:
          paths:
            - node_modules
          key: v1-dependencies-{{ checksum "package.json" }}
      - lambda/store

# Configure workflows & scheduled jobs:
workflows:
  version: 2
  build-deploy:
    jobs:
      - build
      - lambda/deploy:
          name: deploy
          app: hello-serverless
          requires:
            - build
          filters:
            branches:
              only: master
```

After adding this file to your application's repository, [add the app as a "project"](https://circleci.com/docs/2.0/project-build/#section=getting-started). Your first build may fail due to missing credentials - that's okay! Head to the project's "Build Settings" page and [import environment variables](https://circleci.com/docs/2.0/env-vars/#setting-an-environment-variable-in-a-project) from an existing serverless project, such as `dosomething/graphql`.

Now, any commits to `master` [on this repository](https://github.com/DoSomething/hello-serverless) will automatically deploy [our Lambda function](https://hello-serverless.dosomething.org)!

<a href="https://hello-serverless.dosomething.org"><img width="1375" alt="screen shot 2019-02-06 at 6 00 59 pm" src="https://user-images.githubusercontent.com/583202/52379750-59d2cb00-2a39-11e9-986b-88794d0406a1.png"></a>

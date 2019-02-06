# Serverless: Getting Started

**Serverless** technologies like [Lambda](https://aws.amazon.com/lambda/) and [DynamoDB](https://aws.amazon.com/dynamodb/) allow us to write and run code without thinking about servers. Specifically, these technologies allow us to **automatically scale** based on traffic and only **pay for as much as we use**.

### Step 1: Creating our Function
We manage Serverless infrastructure with Terraform. To start, use the `lambda_function` module to provision a
new function. This will create a new function with the given name. It will also create a log group, execution role, deployment bucket, IAM user, and access key.

**Note:** At the moment, we only support functions that run on Node.js 8.x.

```terraform
module "app" {
  source = "../shared/lambda_function"

  name = "serverless-example"
}
```

After you run `make apply`, you should see the function on the [AWS Console](http://console.aws.amazon.com):

![AWS Lambda GUI](https://user-images.githubusercontent.com/583202/52375124-e4f99400-2a2c-11e9-832c-ec6e93b1cf27.png)

We haven't configured the function to accept HTTP requests yet (and not all Serverless functions have to). We can check that everything works by executing this function using the AWS CLI:

```
$ aws lambda invoke --region=us-east-1 --function-name=hello-serverless /dev/stdout

{"statusCode":200,"headers":{"Content-Type":"text/html; charset=utf-8"},"body":"<p>Hello world!</p>"}{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}
```

We're off to a great start! :rocket:

### Step 2: Add HTTP Endpoints (optional)
Often, we'll want our Lambda functions to be accessible via the internet. To do so, let's add an [API Gateway](https://aws.amazon.com/api-gateway/):

```terraform
module "gateway" {
  source = "shared/api_gateway_proxy"

  name                = "hello-serverless"
  environment         = "development"
  function_arn        = "${module.app.arn}"
  function_invoke_arn = "${module.app.invoke_arn}"
}
```

<img width="1375" alt="screen shot 2019-02-06 at 4 56 08 pm" src="https://user-images.githubusercontent.com/583202/52376426-1f186500-2a30-11e9-8548-c043988c530e.png">

We can now execute our Lambda function via the web!

<img width="1375" alt="screen shot 2019-02-06 at 4 57 23 pm" src="https://user-images.githubusercontent.com/583202/52376506-4cfda980-2a30-11e9-904a-57663ab6abd8.png">

If we want to set a custom domain, we just have to provide the `domain` variable to the gateway:

```terraform
module "gateway" {
  # ...
  domain = "hello-serverless.dosomething.org"
}
```

### Step 3: Deploying Code
We deploy serverless applications using [CircleCI](https://circleci.com). 
...


### Step 4: Add a Database
...

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
Often, we want our Lambda functions to be accessible via the internet. To do so, let's add an [API Gateway](https://aws.amazon.com/api-gateway/):

```terraform

```

...

### Step 3: Deploying Code
We deploy serverless applications using [CircleCI](https://circleci.com). 
...


### Step 4: Add a Database
...

# DoSomething.org Infrastructure

This is DoSomething.org's infrastructure as code, built using [Terraform](https://www.terraform.io). We use it to manage and provision resources in [Fastly](https://www.terraform.io/docs/providers/fastly/), [Heroku](https://www.terraform.io/docs/providers/heroku/), and [AWS](https://www.terraform.io/docs/providers/aws/) (EC2, RDS, SQS, S3, IAM users, amongst others). It's a [work in progress](https://github.com/DoSomething/internal/issues/465).

## Installation

Install [Terraform](https://www.terraform.io) 0.11.x, [Landscape](https://github.com/coinbase/terraform-landscape), and the [AWS CLI](https://aws.amazon.com/cli/). On macOS, this is easy with [Homebrew](https://brew.sh):

```sh
brew install awscli terraform terraform_landscape
```

Next, configure secrets (see the "Terraform credentials" secure note in Lastpass) & install dependencies:

```sh
# Configure 'terraform' AWS profile:
aws configure --profile terraform

# Connect to S3 backend & install dependencies:
make init

# Configure other backends w/ secrets from Lastpass:
vi terraform.tfvars
```

## Usage

Terraform allows us to create & modify infrastructure declaratively. You can see all your options in Terraform's provider documentation for [Fastly](https://www.terraform.io/docs/providers/fastly/), [Heroku](https://www.terraform.io/docs/providers/heroku/), and [AWS](https://www.terraform.io/docs/providers/aws/) (EC2, RDS, SQS, S3, IAM users, amongst others).

You can run `make format` at any time to automatically format your code (or use an [hclfmt](https://github.com/fatih/hclfmt#editor-integration) plugin for your editor).

Next, **make a plan** to find out how it will affect the current state of the system:

```sh
make plan
```

Once you're satisfied with Terraform's plan, commit your work & make a pull request. After your pull request is reviewed, you can then **apply your change** to update the actual infrastructure. Terraform will make your changes, update the state in S3, and ensure nobody else makes any changes until you're done:

```sh
make apply
```

See Terraform's [Getting Started guide](https://www.terraform.io/intro/getting-started/build.html) & [documentation](https://www.terraform.io/docs/index.html) for more details.

## Security Vulnerabilities

We take security very seriously. Any vulnerabilities in our infrastructure should be reported to [security@dosomething.org](mailto:security@dosomething.org),
and will be promptly addressed. Thank you for taking the time to responsibly disclose any issues you find.

## License

&copy; DoSomething.org. This config is free software, and may be redistributed under the terms specified
in the [LICENSE](https://github.com/DoSomething/infrastructure/blob/master/LICENSE) file. The name and logo for
DoSomething.org are trademarks of Do Something, Inc and may not be used without permission.


# DoSomething.org Infrastructure

This is a prototype for managing DoSomething.org's infrastructure as code, using [Terraform](https://www.terraform.io). We're currently evaluating whether this is the right tool for us, and migrating services piece-by-piece to test.

## Installation

Install [Terraform](https://www.terraform.io) 0.11.x and the [AWS CLI](https://aws.amazon.com/cli/). Credentials can be found in Lastpass.

```sh
# Configure 'terraform' AWS profile:
aws configure --profile terraform

# Configure other backends w/ variables:
cp {example.,}terraform.tfvars && vi terraform.tfvars

# Install dependencies:
terraform init
```

## Usage

Terraform allows us to create & modify infrastructure declaratively. If you want to make a change, just find the relevant file & edit it. You can see all your options in Terraform's provider documentation for [Fastly](https://www.terraform.io/docs/providers/fastly/), [Heroku](https://www.terraform.io/docs/providers/heroku/), and [AWS](https://www.terraform.io/docs/providers/aws/) (read-only).

You can run `terraform fmt` at any time to automatically format your code (or use an [hclfmt](https://github.com/fatih/hclfmt#editor-integration) plugin for your editor).

Next **plan your change** to find out how it will affect the current state of the system:

```sh
terraform plan
```

Once you're satisfied with your change, commit your work & make a pull request. After your pull request is reviewed, you can then **apply your change** to update the actual infrastructure. Terraform will make your changes, update the state in S3, and ensure nobody else makes any changes until you're done:

```sh
terraform apply
```

See Terraform's [Getting Started guide](https://www.terraform.io/intro/getting-started/install.html) & [documentation](https://www.terraform.io/docs/index.html) for more details.

## Security Vulnerabilities

We take security very seriously. Any vulnerabilities in our infrastructure should be reported to [security@dosomething.org](mailto:security@dosomething.org),
and will be promptly addressed. Thank you for taking the time to responsibly disclose any issues you find.

## License

&copy; DoSomething.org. This config is free software, and may be redistributed under the terms specified
in the [LICENSE](https://github.com/DoSomething/infrastructure/blob/master/LICENSE) file. The name and logo for
DoSomething.org are trademarks of Do Something, Inc and may not be used without permission.


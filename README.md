# DoSomething.org Infrastructure

This is DoSomething.org's infrastructure as code, built using [Terraform](https://www.terraform.io). We use it to manage and provision resources in [Fastly](https://www.terraform.io/docs/providers/fastly/), [Heroku](https://www.terraform.io/docs/providers/heroku/), and [AWS](https://www.terraform.io/docs/providers/aws/) (EC2, RDS, SQS, S3, IAM users, amongst others). It's a [work in progress](https://github.com/DoSomething/internal/issues/465).

## Installation

Install [Terraform](https://www.terraform.io) 0.12. On macOS, this is easy with [Homebrew](https://brew.sh):

```sh
brew install terraform
```

Create a [Terraform.io account](https://app.terraform.io/account/new) with your work email & ask for an invite to our organization in [#dev-infrastructure](https://dosomething.slack.com/messages/C03T8SDJJ/). Don't forget to [enable two-factor auth](https://www.terraform.io/docs/enterprise/users-teams-organizations/2fa.html)!  Then, [create a user API token](https://www.terraform.io/docs/enterprise/users-teams-organizations/users.html#api-tokens) and place it in your `~/.terraformrc` file, like so:

```hcl
credentials "app.terraform.io" {
  token = "xxxxxx.atlasv1.zzzzzzzzzzzzz"
}
```

Finally, configure your local environment & install dependencies:

```sh
# Install dependencies, connect to Terraform Cloud, and configure git hooks:
make init
```

## Usage

Terraform allows us to create & modify infrastructure declaratively. You can see all your options in Terraform's provider documentation for [Fastly](https://www.terraform.io/docs/providers/fastly/), [Heroku](https://www.terraform.io/docs/providers/heroku/), and [AWS](https://www.terraform.io/docs/providers/aws/) (EC2, RDS, SQS, S3, IAM users, amongst others). We also have "getting started" guides for [Terraform Basics](https://github.com/DoSomething/infrastructure/blob/master/docs/basics-guide.md) & [Serverless](https://github.com/DoSomething/infrastructure/blob/master/docs/serverless-guide.md).

You can run `make format` at any time to automatically format your code (or use an [hclfmt](https://github.com/fatih/hclfmt#editor-integration) plugin for your editor).

Next, **make a plan** to find out how it will affect the current state of the system:

```sh
make plan
```

Once you're satisfied with Terraform's plan, commit your work & make a pull request. After your pull request is reviewed and merged, you can then **apply your change** to update the actual infrastructure. Terraform Cloud will make your changes, update the remote state, and ensure nobody else makes any changes until you're done.

See Terraform's [Getting Started guide](https://www.terraform.io/intro/getting-started/build.html) & [documentation](https://www.terraform.io/docs/index.html) for more details.

## Security Vulnerabilities

We take security very seriously. Any vulnerabilities in our infrastructure should be reported to [security@dosomething.org](mailto:security@dosomething.org),
and will be promptly addressed. Thank you for taking the time to responsibly disclose any issues you find.

## License

&copy; DoSomething.org. This config is free software, and may be redistributed under the terms specified
in the [LICENSE](https://github.com/DoSomething/infrastructure/blob/master/LICENSE) file. The name and logo for
DoSomething.org are trademarks of Do Something, Inc and may not be used without permission.


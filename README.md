# DoSomething.org Infrastructure

This is DoSomething.org's infrastructure as code, built using [Terraform](https://www.terraform.io). We use it to manage and provision resources in [Fastly](https://www.terraform.io/docs/providers/fastly/), [Heroku](https://www.terraform.io/docs/providers/heroku/), and [AWS](https://www.terraform.io/docs/providers/aws/) (EC2, RDS, SQS, S3, IAM users, amongst others). It's a [work in progress](https://github.com/DoSomething/internal/issues/465).

## Installation

Install [Terraform](https://www.terraform.io) 0.12. On macOS, this is easy with [Homebrew](https://brew.sh):

```sh
brew install terraform
```

Create a [Terraform Cloud account](https://app.terraform.io/account/new) with your work email & ask for an invite to our organization in [#dev-infrastructure](https://dosomething.slack.com/messages/C03T8SDJJ/). Don't forget to [enable two-factor auth](https://www.terraform.io/docs/enterprise/users-teams-organizations/2fa.html)!  Then, [create your API token](https://www.terraform.io/docs/enterprise/users-teams-organizations/users.html#api-tokens) and place it in your `~/.terraformrc` file, like so:

```hcl
credentials "app.terraform.io" {
  token = "xxxxxx.atlasv1.zzzzzzzzzzzzz"
}
```

You can run `terraform fmt` at any time to format your code, or install the Terraform extension [for your editor](https://github.com/hashicorp/terraform-ls/blob/main/docs/USAGE.md).

Alright, now you're ready to build some infrastructure!! 🏗

## Usage

Terraform allows us to create & modify infrastructure declaratively. The files in this repository define what infrastructure (apps, databases, queues, domains, etc.) we _should_ have, and Terraform figures out what changes it needs to make the get there based on what currently exists.

We separate our configuration into workspaces. We also build reusable modules in the [`applications/`](https://github.com/DoSomething/infrastructure/tree/main/applications) and [`components/`](https://github.com/DoSomething/infrastructure/tree/main/components) directories that can be used to provision the same type of thing in multiple places.

See Terraform's [Getting Started guide](https://www.terraform.io/intro/getting-started/build.html) & [documentation](https://www.terraform.io/docs/index.html) for more details.

### Plan

We use workspaces to separate different contexts (e.g. the main application vs. our data stack) and environments (proudction, QA, and development). Each workspace exists as a top-level folder in this repository.

To make changes in a workspace, first `cd` into the workspace's directory and run `terraform init` to pull down dependencies. Then, make your changes to the Terraform configuration files with your text editor.

You can **make a plan** to find out how your changes will affect the current state of the system:

```sh
terraform plan
```

Once you're satisfied with Terraform's plan for your changes, commit your work & make a pull request. Your pull request will automatically run a plan for all workspaces (even if they're not affected by your change).

### Apply

After your pull request is reviewed and merged, you can then **apply your change** to update the actual infrastructure. Terraform Cloud will make your changes, update the remote state, and ensure nobody else makes any changes until you're done.

To apply pending changes to a workspace, visit [Terraform Cloud](https://app.terraform.io/app/dosomething/workspaces) and open the latest run for the workspace you want to modify. Review the plan & then choose "Confirm & Apply" to make the change.

## Security Vulnerabilities

We take security very seriously. Any vulnerabilities should be reported to [security@dosomething.org](mailto:security@dosomething.org),
and will be promptly addressed. Thank you for taking the time to responsibly disclose any issues you find.

## References
- [Terraform "Getting Started" Tutorial](https://www.terraform.io/intro/getting-started/build.html) - a "step by step" tutorial on Terraform basics
- [Terraform Configuration Language Reference](https://www.terraform.io/docs/configuration/index.html) – look here for syntax for writing config!
- [Terraform AWS Provider](https://www.terraform.io/docs/providers/aws/) - API documentation for `aws_` resources
- [Terraform Fastly Provider](https://www.terraform.io/docs/providers/fastly/) - API documentation for `fastly_` resources
- [Terraform Heroku Provider](https://www.terraform.io/docs/providers/heroku/) - API documentation for `heroku_` resources
- [Serverless Guide](https://github.com/DoSomething/infrastructure/blob/main/docs/serverless-guide.md) - how to use our "serverless" modules


## License

&copy; DoSomething.org. This config is free software, and may be redistributed under the terms specified
in the [LICENSE](https://github.com/DoSomething/infrastructure/blob/main/LICENSE) file. The name and logo for
DoSomething.org are trademarks of Do Something, Inc and may not be used without permission.


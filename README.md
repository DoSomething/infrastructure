# DoSomething.org Infrastructure

This is a prototype for managing DoSomething.org's infrastructure as code, using [Terraform](https://www.terraform.io). We're currently evaluating whether this is the right tool for us, and migrating services piece-by-piece to test.

## Usage

Install [Terraform](https://www.terraform.io) 0.11.x and the [AWS CLI](https://aws.amazon.com/cli/). Credentials can be found in Lastpass.

```sh
# Set 'terraform' AWS profile:
aws configure --profile terraform

# Configure other backends w/ variables:
cp {example.,}terraform.tfvars && vi terraform.tfvars

# Install dependencies:
terraform init

# Make changes, then plan them:
terraform plan

# If everything looks good, apply!
terraform apply
```

## Security Vulnerabilities

We take security very seriously. Any vulnerabilities in our infrastructure should be reported to [security@dosomething.org](mailto:security@dosomething.org),
and will be promptly addressed. Thank you for taking the time to responsibly disclose any issues you find.

## License

&copy; DoSomething.org. This config is free software, and may be redistributed under the terms specified
in the [LICENSE](https://github.com/DoSomething/infrastructure/blob/master/LICENSE) file. The name and logo for
DoSomething.org are trademarks of Do Something, Inc and may not be used without permission.


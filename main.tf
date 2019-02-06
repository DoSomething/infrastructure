# Welcome to our Terraform infrastructure! We store
# infrastructure as code to easily collaborate, track
# changes, and visualize how our systems are hooked up.

# ----------------------------------------------------

# We store secrets in `terraform.tfvars` to keep them
# out of version control. You can find the values for
# each of these in Lastpass.

variable "fastly_api_key" {}
variable "heroku_email" {}
variable "heroku_api_key" {}
variable "papertrail_prod_destination" {}
variable "papertrail_qa_destination" {}
variable "papertrail_destination_fastly_dev" {}
variable "papertrail_destination_fastly_qa" {}
variable "papertrail_destination_fastly" {}

# ----------------------------------------------------

# We store our Terraform state (what the whole system
# currently looks like) in a private S3 bucket, and use
# a DynamoDB table to "lock" the system so only one
# person can make changes at a time.
terraform {
  backend "s3" {
    bucket         = "dosomething-infrastructure-state"
    dynamodb_table = "dosomething-infrastructure-locks"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    profile        = "terraform"
    encrypt        = true
  }
}

# ----------------------------------------------------

# We use Fastly as our content delivery network. It sits
# in front of (most of) our services & handles caching,
# backend-routing, geolocation, redirects, etc.
provider "fastly" {
  version = "~> 0.4"
  api_key = "${var.fastly_api_key}"
}

# We host many apps in Heroku, a platform-as-a-service
# which handles a lot of operations concerns for us out
# of the box. We include these services in Terraform for
# visibility & to make cross-cloud dependencies (like AWS
# resources or Fastly backends) easier to hook up.
provider "heroku" {
  version = "~> 1.5"
  email   = "${var.heroku_email}"
  api_key = "${var.heroku_api_key}"
}

# We use Amazon Web Services (AWS) for databases (RDS),
# storage (S3), queueing (SQS), functions (Lambda), and
# some legacy servers on EC2. AWS credentials are stored
# using the `aws` CLI (see installation instructions).
provider "aws" {
  version = "~> 1.56"
  region  = "us-east-1"
  profile = "terraform"
}

# In some cases, like backup buckets, we store resources
# in Amazon's US West region.
provider "aws" {
  alias   = "west"
  region  = "us-west-1"
  profile = "terraform"
}

# The template provider is used to generate files with
# interpolated variables (like JSON or VCL).
provider "template" {
  version = "~> 1.0"
}

# The random provider is used for secret generation.
provider "random" {
  version = "~> 2.0"
}

# ----------------------------------------------------

module "app" {
  source = "shared/lambda_function"

  name = "hello-serverless"
}

module "gateway" {
  source = "shared/api_gateway_proxy"

  name                = "hello-serverless"
  environment         = "development"
  function_arn        = "${module.app.arn}"
  function_invoke_arn = "${module.app.invoke_arn}"
}

# We separate our infrastructure into modules for
# organization & to make dependencies explicit by
# importing and exporting variables.

# Some top-level resources (like Heroku pipelines)
# are shared among all environments:
module "shared" {
  source = "shared"
}

# Our core production applications live in the 
# 'dosomething' stack. This is where our real user
# traffic & data lives, so changes should be tested
# in 'dosomething-qa' below first.
module "dosomething" {
  source = "dosomething"

  graphql_pipeline              = "${module.shared.graphql_pipeline}"
  northstar_pipeline            = "${module.shared.northstar_pipeline}"
  phoenix_pipeline              = "${module.shared.phoenix_pipeline}"
  rogue_pipeline                = "${module.shared.rogue_pipeline}"
  papertrail_destination        = "${var.papertrail_prod_destination}"
  papertrail_destination_fastly = "${var.papertrail_destination_fastly}"
}

# Our QA applications live in the 'dosomething-qa' stack.
# This is a (scaled down) copy of our production environment
# where we test new changes before they affect real traffic.
module "dosomething-qa" {
  source = "dosomething-qa"

  graphql_pipeline              = "${module.shared.graphql_pipeline}"
  northstar_pipeline            = "${module.shared.northstar_pipeline}"
  phoenix_pipeline              = "${module.shared.phoenix_pipeline}"
  rogue_pipeline                = "${module.shared.rogue_pipeline}"
  papertrail_destination        = "${var.papertrail_qa_destination}"
  papertrail_destination_fastly = "${var.papertrail_destination_fastly_qa}"
}

# Our development applications live in the 'dosomething-dev'
# stack. This is a (scaled down) copy of our production
# environment with test & sandbox data.
module "dosomething-dev" {
  source = "dosomething-dev"

  graphql_pipeline              = "${module.shared.graphql_pipeline}"
  northstar_pipeline            = "${module.shared.northstar_pipeline}"
  phoenix_pipeline              = "${module.shared.phoenix_pipeline}"
  rogue_pipeline                = "${module.shared.rogue_pipeline}"
  papertrail_destination        = "${var.papertrail_qa_destination}"
  papertrail_destination_fastly = "${var.papertrail_destination_fastly_dev}"
}

# Longshot is DoSomething Strategic's white-labeled scholarship
# application, used by clients like Footlocker and H&R Block.
module "longshot" {
  source = "longshot"

  papertrail_prod_destination = "${var.papertrail_prod_destination}"
  papertrail_qa_destination   = "${var.papertrail_qa_destination}"
}

# Quasar is DoSomething's Data Platform. This environment is
# primarily used by Team Storm.
module "quasar" {
  source = "quasar"
}

# The redirects property handles redirects for old domains, like
# 'northstar-thor.dosomething.org' to 'identity-qa.dosomething.org'.
module "redirects" {
  source = "redirects"
}

# The voter registration landing page <vote.dosomething.org>
# is hosted on Instapage, with optional fallback to S3.
module "vote" {
  source = "vote"

  papertrail_destination = "${var.papertrail_destination_fastly}"
}

# The voting application (https://git.io/fAsod) once hosted
# voting campaigns like Celebs Gone Good & Athletes Gone Good.
module "voting-app" {
  source = "voting-app"
}

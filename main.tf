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
  version = "~> 0.3"
  api_key = "${var.fastly_api_key}"
}

# We host many apps in Heroku, a platform-as-a-service
# which handles a lot of operations concerns for us out
# of the box. We include these services in Terraform for
# visibility & to make cross-cloud dependencies (like AWS
# resources or Fastly backends) easier to hook up.
provider "heroku" {
  version = "~> 1.3"
  email   = "${var.heroku_email}"
  api_key = "${var.heroku_api_key}"
}

# We use Amazon Web Services (AWS) for databases (RDS),
# storage (S3), queueing (SQS), functions (Lambda), and
# some legacy servers on EC2. AWS credentials are stored
# using the `aws` CLI (see installation instructions).
provider "aws" {
  version = "~> 1.33"
  region  = "us-east-1"
  profile = "terraform"
}

# ----------------------------------------------------

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

  graphql_pipeline       = "${module.shared.graphql_pipeline}"
  papertrail_destination = "${var.papertrail_prod_destination}"
}

# Our development & QA applications live in the combined
# 'dosomething-qa' stack. This is a (scaled down) copy of
# our production stack where we test new changes.
module "dosomething-qa" {
  source = "dosomething-qa"

  graphql_pipeline       = "${module.shared.graphql_pipeline}"
  northstar_pipeline     = "${module.shared.northstar_pipeline}"
  rogue_pipeline         = "${module.shared.rogue_pipeline}"
  papertrail_destination = "${var.papertrail_qa_destination}"
}

# The voting application (https://git.io/fAsod) once hosted
# voting campaigns like Celebs Gone Good & Athletes Gone Good.
module "voting-app" {
  source = "voting-app"
}

# The miscellaneous property acts as a catch-all for smaller
# applications that don't fit into another bucket, or utilities
# like our Fastly domain redirect property.
module "misc" {
  source = "misc"
}

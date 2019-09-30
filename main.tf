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
# currently looks like) in Terraform Enterprise.
terraform {
  backend "remote" {
    organization = "dosomething"

    workspaces {
      name = "infrastructure"
    }
  }
}

# ----------------------------------------------------

# We use Fastly as our content delivery network. It sits
# in front of (most of) our services & handles caching,
# backend-routing, geolocation, redirects, etc.
provider "fastly" {
  version = "0.9.0"
  api_key = var.fastly_api_key
}

# We host many apps in Heroku, a platform-as-a-service
# which handles a lot of operations concerns for us out
# of the box. We include these services in Terraform for
# visibility & to make cross-cloud dependencies (like AWS
# resources or Fastly backends) easier to hook up.
provider "heroku" {
  version = "2.2.0"
  email   = var.heroku_email
  api_key = var.heroku_api_key
}

# We use Amazon Web Services (AWS) for databases (RDS),
# storage (S3), queueing (SQS), functions (Lambda), and
# some legacy servers on EC2. AWS credentials are stored
# using the `aws` CLI (see installation instructions).
provider "aws" {
  version = "2.30.0"
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
  version = "~> 2.1"
}

# The random provider is used for secret generation.
provider "random" {
  version = "~> 2.0"
}

# Finally, we use the 'null' provider for some hacks, like
# running a shell script when a resource changes.
provider "null" {
  version = "~> 2.1"
}

# ----------------------------------------------------

# We separate our infrastructure into modules for
# organization & to make dependencies explicit by
# importing and exporting variables.

# Some top-level resources (like Heroku pipelines)
# are shared among all environments:
module "shared" {
  source = "./shared"
}

# Our core production applications live in the 
# 'dosomething' stack. This is where our real user
# traffic & data lives, so changes should be tested
# in 'dosomething-qa' below first.
module "dosomething" {
  source = "./dosomething"

  providers = {
    aws      = aws
    aws.west = aws.west
  }

  northstar_pipeline            = module.shared.northstar_pipeline
  phoenix_pipeline              = module.shared.phoenix_pipeline
  rogue_pipeline                = module.shared.rogue_pipeline
  papertrail_forwarder          = module.papertrail
  papertrail_destination        = var.papertrail_prod_destination
  papertrail_destination_fastly = var.papertrail_destination_fastly
}

# Our QA applications live in the 'dosomething-qa' stack.
# This is a (scaled down) copy of our production environment
# where we test new changes before they affect real traffic.
module "dosomething-qa" {
  source = "./dosomething-qa"

  northstar_pipeline            = module.shared.northstar_pipeline
  phoenix_pipeline              = module.shared.phoenix_pipeline
  rogue_pipeline                = module.shared.rogue_pipeline
  papertrail_destination        = var.papertrail_qa_destination
  papertrail_destination_fastly = var.papertrail_destination_fastly_qa
}

# Our development applications live in the 'dosomething-dev'
# stack. This is a (scaled down) copy of our production
# environment with test & sandbox data.
module "dosomething-dev" {
  source = "./dosomething-dev"

  northstar_pipeline            = module.shared.northstar_pipeline
  phoenix_pipeline              = module.shared.phoenix_pipeline
  rogue_pipeline                = module.shared.rogue_pipeline
  papertrail_destination        = var.papertrail_qa_destination
  papertrail_destination_fastly = var.papertrail_destination_fastly_dev
}

# Longshot is DoSomething Strategic's white-labeled scholarship
# application, used by clients like Footlocker and H&R Block.
module "longshot" {
  source = "./longshot"

  papertrail_prod_destination = var.papertrail_prod_destination
  papertrail_qa_destination   = var.papertrail_qa_destination
}

# Quasar is DoSomething's Data Platform. This environment is
# primarily used by Team Storm.
module "quasar" {
  source = "./quasar"

  papertrail_forwarder = module.papertrail
}

# The redirects property handles redirects for old domains, like
# 'northstar-thor.dosomething.org' to 'identity-qa.dosomething.org'.
module "redirects" {
  source = "./redirects"
}

# The voter registration landing page <vote.dosomething.org>
# is hosted on Instapage, with optional fallback to S3.
module "vote" {
  source = "./vote"

  papertrail_destination = var.papertrail_destination_fastly
}

# The voting application (https://git.io/fAsod) once hosted
# voting campaigns like Celebs Gone Good & Athletes Gone Good.
module "voting-app" {
  source = "./voting-app"
}

# We use this Lambda function to forward logs to Papertrail
# for production applications & our Quasar warehouse.
module "papertrail" {
  source = "./applications/papertrail"

  environment            = "production"
  name                   = "papertrail"
  papertrail_destination = var.papertrail_prod_destination
}


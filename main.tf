variable "fastly_api_key" {}
variable "heroku_email" {}
variable "heroku_api_key" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "papertrail_prod_destination" {}
variable "papertrail_qa_destination" {}

provider "fastly" {
  version = "~> 0.3"
  api_key="${var.fastly_api_key}"
}

provider "heroku" {
  version = "~> 1.3"
  email="${var.heroku_email}"
  api_key="${var.heroku_api_key}"
}

provider "aws" {
  version = "~> 1.33"
  region= "us-east-1"
  access_key= "${var.aws_access_key}"
  secret_key= "${var.aws_secret_key}"
}

module "shared" {
  source = "shared"
}

module "dosomething" {
  source = "dosomething"

  graphql_pipeline="${module.shared.graphql_pipeline}"
  papertrail_destination="${var.papertrail_prod_destination}"
}

module "dosomething-qa" {
  source = "dosomething-qa"

  graphql_pipeline="${module.shared.graphql_pipeline}"
  papertrail_destination="${var.papertrail_qa_destination}"
}

module "voting-app" {
  source = "voting-app"
}

module "voting-app-qa" {
  source = "voting-app-qa"
}

module "misc" {
  source = "misc"
}

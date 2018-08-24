variable "fastly_api_key" {}
variable "heroku_email" {}
variable "heroku_api_key" {}

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

module "dosomething-qa" {
  source = "dosomething-qa"

  papertrail_qa_destination="${var.papertrail_qa_destination}"
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

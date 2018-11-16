variable "papertrail_prod_destination" {}
variable "papertrail_qa_destination" {}

resource "heroku_pipeline" "longshot" {
  name = "longshot"
}

module "longshot-qa" {
  source = "application"

  name           = "longshot-qa"
  host           = "longshot-qa.dosomething.org"
  pipeline       = "${heroku_pipeline.longshot.id}"
  pipeline_stage = "staging"

  email_name    = "Longshot QA"
  email_address = "devops@dosomething.org"

  database_name = "whitelabel_scholarship"
  database_type = "db.t2.micro"
  database_size = 5

  papertrail_destination = "${var.papertrail_qa_destination}"
}

module "longshot-footlocer-internal" {
  source = "application"

  name           = "longshot-footlocker-internal"
  host           = "footlocker-internal.dosomething.org"
  pipeline       = "${heroku_pipeline.longshot.id}"
  pipeline_stage = "production"

  email_name    = "Foot Locker Scholar Athletes"
  email_address = "footlocker@tmiagency.org"

  database_name = "footlocker_internal"
  database_type = "db.t2.medium"

  papertrail_destination = "${var.papertrail_prod_destination}"
}

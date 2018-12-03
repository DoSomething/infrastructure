variable "papertrail_prod_destination" {}
variable "papertrail_qa_destination" {}

resource "heroku_pipeline" "longshot" {
  name = "longshot"
}

module "longshot-qa" {
  source = "application"

  name        = "longshot-qa"
  domain      = "longshot-qa.dosomething.org"
  pipeline    = "${heroku_pipeline.longshot.id}"
  environment = "qa"

  email_name    = "Longshot QA"
  email_address = "devops@dosomething.org"

  database_type    = "db.t2.micro"
  database_size_gb = 5
  papertrail_destination = "${var.papertrail_qa_destination}"
}

module "longshot-footlocker" {
  source = "application"

  name        = "longshot-footlocker"
  domain      = "footlockerscholarathletes.com"
  pipeline    = "${heroku_pipeline.longshot.id}"
  environment = "production"

  email_name    = "Foot Locker Scholar Athletes"
  email_address = "footlocker@tmiagency.org"

  database_type = "db.t2.medium"

  papertrail_destination = "${var.papertrail_prod_destination}"
  with_newrelic          = true
}

module "longshot-footlocker-internal" {
  source = "application"

  name        = "longshot-footlocker-internal"
  domain      = "footlocker-internal.dosomething.org"
  pipeline    = "${heroku_pipeline.longshot.id}"
  environment = "production"

  email_name    = "Foot Locker Scholar Athletes"
  email_address = "footlocker@tmiagency.org"

  database_type = "db.t2.medium"

  papertrail_destination = "${var.papertrail_prod_destination}"
}

module "hrblock" {
  source = "application"

  name        = "longshot-hrblock"
  domain      = "caps.hrblock.com"
  pipeline    = "${heroku_pipeline.longshot.id}"
  environment = "production"

  email_name    = "Kary at CAPS"
  email_address = "contracts@tmiagency.org"

  database_type = "db.t2.medium"

  papertrail_destination = "${var.papertrail_prod_destination}"
  with_newrelic          = true
}

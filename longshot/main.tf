variable "papertrail_prod_destination" {}
variable "papertrail_qa_destination" {}

resource "heroku_pipeline" "longshot" {
  name = "longshot"
}

module "dosomething-qa" {
  source = "application"

  name           = "longshot-qa"
  host           = "longshot-qa.dosomething.org"
  pipeline       = "${heroku_pipeline.longshot.id}"
  pipeline_stage = "staging"

  email_name    = "Longshot QA"
  email_address = "devops@dosomething.org"

  database_name  = "whitelabel_scholarship"
  database_type  = "db.t2.micro"
  database_scale = 5

  papertrail_destination = "${var.papertrail_qa_destination}"
}

# This template builds a Rogue application instance.
#
# Manual setup steps:
#  - TBD! Talk to Chloe and/or Dave! :)
#
# NOTE: We'll move more of these steps into Terraform over time!

# Required variables:
variable "name" {
  description = "The application name."
}

# TODO: Use our 'heroku_app' module to configure more of this!
resource "heroku_app" "app" {
  name   = "${var.name}"
  region = "us"

  organization {
    name = "dosomething"
  }

  config_vars = {
    IMPORTER_API_KEY = "lalalala"
  }

  buildpacks = [
    "heroku/nodejs",
    "heroku/php",
  ]

  acm = true
}

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

resource "random_string" "callpower_api_key" {
  length = 32
}

resource "random_string" "softedge_api_key" {
  length = 32
}

# TODO: Use our 'heroku_app' module to configure more of this!
resource "heroku_app" "app" {
  name   = "${var.name}"
  region = "us"

  organization {
    name = "dosomething"
  }

  config_vars = {
    CALLPOWER_API_KEY = "${random_string.callpower_api_key.result}"
    SOFTEDGE_API_KEY  = "${random_string.softedge_api_key.result}"

    # TODO: Remove this once DoSomething/chompy#93 is deployed. <https://git.io/fjEeg>
    IMPORTER_API_KEY = "${random_string.callpower_api_key.result}"
  }

  buildpacks = [
    "heroku/nodejs",
    "heroku/php",
  ]

  acm = true
}

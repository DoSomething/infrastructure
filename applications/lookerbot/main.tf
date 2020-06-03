# This template builds an S3 bucket for a Lookerbot instance.
#
# See https://github.com/looker/lookerbot#amazon-s3
#
# Manual setup steps:
#   - Head to <https://git.io/fh9DS> and hit "Deploy to Heroku" to provision the
#     app.
#   - Set the required environment variables via Heroku's admin panel.
#     <https://git.io/fh9Dy>
#   - Set the `SLACKBOT_S3_BUCKET`, `AWS_ACCESS_KEY_ID` &
#     `AWS_SECRET_ACCESS_KEY` environment variables from the resources we've
#     provisioned in this module.
#
# NOTE: If this ends up being how we want to host & manage Lookerbot, we'll move
# more of these steps into Terraform over time!

# Required variables:
variable "name" {
  description = "The application name."
}

module "iam_user" {
  source = "../../components/iam_app_user"
  name   = var.name
}

module "storage" {
  source = "../../components/s3_bucket"

  name    = var.name
  user    = module.iam_user.name
  private = false
}

output "name" {
  value = var.name
}


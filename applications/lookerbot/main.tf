# This template builds an S3 bucket for a Lookerbot instance.
#
# See https://github.com/looker/lookerbot#amazon-s3
#
# Manual setup steps:
#   - Finally, head to the S3 Bucket in AWS after provisioning, and go to the
#     Permissions -> Public Access Settings screen. Check all the options.
#
# NOTE: We'll move more of these steps into Terraform over time!

# Required variables:
variable "name" {
  description = "The application name."
}

module "iam_user" {
  source = "../../shared/iam_app_user"
  name   = "${var.name}"
}

module "storage" {
  source = "../../shared/s3_bucket"

  name = "${var.name}"
  user = "${module.iam_user.name}"
}

output "name" {
  value = "${var.name}"
}

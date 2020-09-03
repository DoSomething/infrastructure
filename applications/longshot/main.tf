# This template manages resources for old Longshot apps,
# a retired scholarship application run by DSS.

# Required variables:
variable "environment" {
  description = "The environment for this application: development, qa, or production."
}

variable "name" {
  description = "The application name."
}

module "storage" {
  source = "../../components/s3_bucket"

  application = "dosomething-longshot"
  name        = var.name
  environment = var.environment
  stack       = "web"

  private  = true
  archived = true
}

output "name" {
  value = var.name
}

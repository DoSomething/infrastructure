variable "environment" {
  description = "The environment we're using: development, qa, or production."
}

variable "name" {
  description = "The application name, e.g. 'dosomething-bertly'."
}

variable "bucket" {
  description = "The s3_bucket resource to configure a Fivetran connector for."
}
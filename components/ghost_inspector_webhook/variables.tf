variable "environment" {
  description = "The environment for this application: development, qa, or production."
}

variable "name" {
  description = "The name of the Heroku application resource to attach this webhook to."
}

/*
 ******************************************************
 * Copyright (C) 2019 tropos.io <team@tropos.io>
 *
 ******************************************************
 */

variable "fivetran_cloudwatch_integration_external_id" {
  description = "External ID for the trust relationship between fivetran and AWS"
}

variable "aws_region" {
  description = "The region where the resources will be deployed"
  default = "eu-west-1"
}
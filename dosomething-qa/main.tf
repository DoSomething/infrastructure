variable "papertrail_qa_destination" {}

module "fastly" {
  source = "fastly"

  graphql_name_dev="${module.graphql.name_dev}"
  graphql_domain_dev="${module.graphql.domain_dev}"
  graphql_backend_dev="${module.graphql.backend_dev}"
  graphql_name_qa="${module.graphql.name_qa}"
  graphql_domain_qa="${module.graphql.domain_qa}"
  graphql_backend_qa="${module.graphql.backend_qa}"
}

module "graphql" {
  source = "graphql"

  papertrail_qa_destination="${var.papertrail_qa_destination}"
}


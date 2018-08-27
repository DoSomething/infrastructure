variable "graphql_name" {}
variable "graphql_domain" {}
variable "graphql_backend" {}

resource "fastly_service_v1" "dosomething" {
  name          = "Terraform: DoSomething"
  force_destroy = true

  domain {
    name = "${var.graphql_domain}"
  }

  condition {
    type      = "REQUEST"
    name      = "backend-graphql"
    statement = "req.http.host == \"${var.graphql_domain}\""
  }

  backend {
    address           = "${var.graphql_backend}"
    name              = "${var.graphql_name}"
    request_condition = "backend-graphql"
    port              = 443
  }
}

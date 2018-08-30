variable "graphql_name_dev" {}
variable "graphql_domain_dev" {}
variable "graphql_backend_dev" {}
variable "graphql_name_qa" {}
variable "graphql_domain_qa" {}
variable "graphql_backend_qa" {}
variable "ashes_backend_staging" {}

resource "fastly_service_v1" "dosomething-qa" {
  name          = "Terraform: DoSomething (QA)"
  force_destroy = true

  domain {
    name = "${var.graphql_domain_dev}"
  }

  domain {
    name = "${var.graphql_domain_qa}"
  }

  domain {
    name = "staging.dosomething.org"
  }

  condition {
    type      = "REQUEST"
    name      = "backend-graphql-dev"
    statement = "req.http.host == \"${var.graphql_domain_dev}\""
  }

  condition {
    type      = "REQUEST"
    name      = "backend-graphql-qa"
    statement = "req.http.host == \"${var.graphql_domain_qa}\""
  }

  condition {
    type      = "REQUEST"
    name      = "path-robots"
    statement = "req.url.basename == \"robots.txt\""
  }

  condition {
    type      = "REQUEST"
    name      = "backend-ashes-staging"
    statement = "req.http.host == \"staging.dosomething.org\""
  }

  backend {
    address           = "${var.graphql_backend_dev}"
    name              = "${var.graphql_name_dev}"
    request_condition = "backend-graphql-dev"
    auto_loadbalance  = false
    port              = 443
  }

  backend {
    address           = "${var.graphql_backend_qa}"
    name              = "${var.graphql_name_qa}"
    request_condition = "backend-graphql-qa"
    auto_loadbalance  = false
    port              = 443
  }

  backend {
    address           = "${var.ashes_backend_staging}"
    name              = "ashes-staging"
    request_condition = "backend-ashes-staging"
    ssl_cert_hostname = "staging.dosomething.org"
    ssl_sni_hostname  = "staging.dosomething.org"
    auto_loadbalance  = false
    use_ssl           = true
    port              = 443
  }

  gzip {
    name = "gzip"

    extensions = ["css", "js", "html", "eot", "ico", "otf", "ttf", "json"]

    content_types = [
      "text/html",
      "application/x-javascript",
      "text/css",
      "application/javascript",
      "text/javascript",
      "application/json",
      "application/vnd.ms-fontobject",
      "application/x-font-opentype",
      "application/x-font-truetype",
      "application/x-font-ttf",
      "application/xml",
      "font/eot",
      "font/opentype",
      "font/otf",
      "image/svg+xml",
      "image/vnd.microsoft.icon",
      "text/plain",
      "text/xml",
    ]
  }

  header {
    name        = "Country Code"
    type        = "request"
    action      = "set"
    source      = "geoip.country_code"
    destination = "http.X-Fastly-Country-Code"
  }

  header {
    name        = "Country Code (Debug)"
    type        = "response"
    action      = "set"
    source      = "geoip.country_code"
    destination = "http.X-Fastly-Country-Code"
  }

  request_setting {
    name      = "Force SSL"
    force_ssl = true
  }

  response_object {
    name              = "robots.txt deny"
    content           = "${file("${path.module}/robots.txt")}"
    request_condition = "path-robots"
  }
}

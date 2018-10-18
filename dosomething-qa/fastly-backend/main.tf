variable "graphql_name_qa" {}
variable "graphql_domain_qa" {}
variable "graphql_backend_qa" {}
variable "northstar_name_qa" {}
variable "northstar_domain_qa" {}
variable "northstar_backend_qa" {}
variable "phoenix_name_qa" {}
variable "phoenix_domain_qa" {}
variable "phoenix_backend_qa" {}
variable "rogue_name_qa" {}
variable "rogue_domain_qa" {}
variable "rogue_backend_qa" {}
variable "papertrail_destination_fastly_qa" {}

resource "fastly_service_v1" "backends-qa" {
  name          = "Terraform: Backends (QA)"
  force_destroy = true

  domain {
    name = "${var.graphql_domain_qa}"
  }

  domain {
    name = "${var.northstar_domain_qa}"
  }

  domain {
    name = "${var.phoenix_domain_qa}"
  }

  domain {
    name = "${var.rogue_domain_qa}"
  }

  condition {
    type      = "REQUEST"
    name      = "backend-graphql-qa"
    statement = "req.http.host == \"${var.graphql_domain_qa}\""
  }

  condition {
    type      = "REQUEST"
    name      = "backend-northstar-qa"
    statement = "req.http.host == \"${var.northstar_domain_qa}\""
  }

  condition {
    type      = "REQUEST"
    name      = "backend-phoenix-qa"
    statement = "req.http.host == \"${var.phoenix_domain_qa}\""
  }

  condition {
    type      = "REQUEST"
    name      = "backend-rogue-qa"
    statement = "req.http.host == \"${var.rogue_domain_qa}\""
  }

  condition {
    type      = "REQUEST"
    name      = "path-robots"
    statement = "req.url.basename == \"robots.txt\""
  }

  backend {
    address           = "${var.graphql_backend_qa}"
    name              = "${var.graphql_name_qa}"
    request_condition = "backend-graphql-qa"
    auto_loadbalance  = false
    port              = 443
  }

  backend {
    address           = "${var.northstar_backend_qa}"
    name              = "${var.northstar_name_qa}"
    request_condition = "backend-northstar-qa"
    auto_loadbalance  = false
    port              = 443
  }

  backend {
    address           = "${var.phoenix_backend_qa}"
    name              = "${var.phoenix_name_qa}"
    request_condition = "backend-phoenix-qa"
    auto_loadbalance  = false
    port              = 443
  }

  backend {
    address           = "${var.rogue_backend_qa}"
    name              = "${var.rogue_name_qa}"
    request_condition = "backend-rogue-qa"
    auto_loadbalance  = false
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
    content           = "${file("${path.root}/shared/deny-robots.txt")}"
    request_condition = "path-robots"
  }

  snippet {
    name    = "GDPR - Redirects Table"
    type    = "init"
    content = "${file("${path.root}/shared/gdpr_init.vcl")}"
  }

  snippet {
    name    = "GDPR - Trigger Redirect"
    type    = "recv"
    content = "${file("${path.root}/shared/gdpr_recv.vcl")}"
  }

  snippet {
    name    = "GDPR - Handle Redirect"
    type    = "error"
    content = "${file("${path.root}/shared/gdpr_error.vcl")}"
  }

  snippet {
    name    = "Shared - Set X-Origin-Name Header"
    type    = "fetch"
    content = "${file("${path.root}/shared/origin_name.vcl")}"
  }

  condition {
    type      = "RESPONSE"
    name      = "errors-northstar-qa"
    statement = "req.http.host == \"${var.northstar_domain_qa}\" && resp.status > 501 && resp.status < 600"
  }

  papertrail {
    name               = "northstar-qa"
    address            = "${element(split(":", var.papertrail_destination_fastly_qa), 0)}"
    port               = "${element(split(":", var.papertrail_destination_fastly_qa), 1)}"
    format             = "%t '%r' status=%>s bytes=%b microseconds=%D"
    response_condition = "errors-northstar-qa"
  }

  condition {
    type      = "RESPONSE"
    name      = "errors-phoenix-qa"
    statement = "req.http.host == \"${var.phoenix_domain_qa}\" && resp.status > 501 && resp.status < 600"
  }

  papertrail {
    name               = "phoenix-qa"
    address            = "${element(split(":", var.papertrail_destination_fastly_qa), 0)}"
    port               = "${element(split(":", var.papertrail_destination_fastly_qa), 1)}"
    format             = "%t '%r' status=%>s bytes=%b microseconds=%D"
    response_condition = "errors-phoenix-qa"
  }

  condition {
    type      = "RESPONSE"
    name      = "errors-rogue-qa"
    statement = "req.http.host == \"${var.rogue_domain_qa}\" && resp.status > 501 && resp.status < 600"
  }

  papertrail {
    name               = "rogue-qa"
    address            = "${element(split(":", var.papertrail_destination_fastly_qa), 0)}"
    port               = "${element(split(":", var.papertrail_destination_fastly_qa), 1)}"
    format             = "%t '%r' status=%>s bytes=%b microseconds=%D"
    response_condition = "errors-rogue-qa"
  }

  condition {
    type      = "RESPONSE"
    name      = "errors-graphql-qa"
    statement = "req.http.host == \"${var.graphql_domain_qa}\" && resp.status > 501 && resp.status < 600"
  }

  papertrail {
    name               = "graphql-qa"
    address            = "${element(split(":", var.papertrail_destination_fastly_qa), 0)}"
    port               = "${element(split(":", var.papertrail_destination_fastly_qa), 1)}"
    format             = "%t '%r' status=%>s bytes=%b microseconds=%D"
    response_condition = "errors-graphql-qa"
  }
}

variable "graphql_name_dev" {}
variable "graphql_domain_dev" {}
variable "graphql_backend_dev" {}
variable "northstar_name_dev" {}
variable "northstar_domain_dev" {}
variable "northstar_backend_dev" {}
variable "rogue_name_dev" {}
variable "rogue_domain_dev" {}
variable "rogue_backend_dev" {}
variable "papertrail_destination_fastly_dev" {}

resource "fastly_service_v1" "backends-dev" {
  name          = "Terraform: Backends (Development)"
  force_destroy = true

  domain {
    name = "${var.graphql_domain_dev}"
  }

  domain {
    name = "${var.northstar_domain_dev}"
  }

  domain {
    name = "${var.rogue_domain_dev}"
  }

  condition {
    type      = "REQUEST"
    name      = "backend-graphql-dev"
    statement = "req.http.host == \"${var.graphql_domain_dev}\""
  }

  condition {
    type      = "REQUEST"
    name      = "backend-northstar-dev"
    statement = "req.http.host == \"${var.northstar_domain_dev}\""
  }

  condition {
    type      = "REQUEST"
    name      = "backend-rogue-dev"
    statement = "req.http.host == \"${var.rogue_domain_dev}\""
  }

  condition {
    type      = "REQUEST"
    name      = "path-robots"
    statement = "req.url.basename == \"robots.txt\""
  }

  backend {
    address           = "${var.graphql_backend_dev}"
    name              = "${var.graphql_name_dev}"
    request_condition = "backend-graphql-dev"
    auto_loadbalance  = false
    port              = 443
  }

  backend {
    address           = "${var.northstar_backend_dev}"
    name              = "${var.northstar_name_dev}"
    request_condition = "backend-northstar-dev"
    auto_loadbalance  = false
    port              = 443
  }

  backend {
    address           = "${var.rogue_backend_dev}"
    name              = "${var.rogue_name_dev}"
    request_condition = "backend-rogue-dev"
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
    name      = "errors-northstar-dev"
    statement = "req.http.host == \"${var.northstar_domain_dev}\" && resp.status > 501 && resp.status < 600"
  }

  papertrail {
    name               = "northstar-dev"
    address            = "${element(split(":", var.papertrail_destination_fastly_dev), 0)}"
    port               = "${element(split(":", var.papertrail_destination_fastly_dev), 1)}"
    format             = "%t '%r' status=%>s bytes=%b microseconds=%D"
    response_condition = "errors-northstar-dev"
  }

  condition {
    type      = "RESPONSE"
    name      = "errors-rogue-dev"
    statement = "req.http.host == \"${var.rogue_domain_dev}\" && resp.status > 501 && resp.status < 600"
  }

  papertrail {
    name               = "rogue-dev"
    address            = "${element(split(":", var.papertrail_destination_fastly_dev), 0)}"
    port               = "${element(split(":", var.papertrail_destination_fastly_dev), 1)}"
    format             = "%t '%r' status=%>s bytes=%b microseconds=%D"
    response_condition = "errors-rogue-dev"
  }

  condition {
    type      = "RESPONSE"
    name      = "errors-graphql-dev"
    statement = "req.http.host == \"${var.graphql_domain_dev}\" && resp.status > 501 && resp.status < 600"
  }

  papertrail {
    name               = "graphql-dev"
    address            = "${element(split(":", var.papertrail_destination_fastly_dev), 0)}"
    port               = "${element(split(":", var.papertrail_destination_fastly_dev), 1)}"
    format             = "%t '%r' status=%>s bytes=%b microseconds=%D"
    response_condition = "errors-graphql-dev"
  }
}

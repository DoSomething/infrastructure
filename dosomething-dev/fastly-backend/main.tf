variable "graphql_name" {}
variable "graphql_domain" {}
variable "graphql_backend" {}
variable "northstar_name" {}
variable "northstar_domain" {}
variable "northstar_backend" {}
variable "phoenix_name" {}
variable "phoenix_domain" {}
variable "phoenix_backend" {}
variable "rogue_name" {}
variable "rogue_domain" {}
variable "rogue_backend" {}
variable "papertrail_destination" {}

variable "papertrail_log_format" {
  default = "%t '%r' status=%>s cache=%{X-Cache}o country=%{X-Fastly-Country-Code}o bytes=%b microseconds=%D"
}

resource "fastly_service_v1" "backends-dev" {
  name          = "Terraform: Backends (Development)"
  force_destroy = true

  domain {
    name = "${var.graphql_domain}"
  }

  domain {
    name = "${var.northstar_domain}"
  }

  domain {
    name = "${var.phoenix_domain}"
  }

  domain {
    name = "${var.rogue_domain}"
  }

  condition {
    type      = "REQUEST"
    name      = "backend-graphql-dev"
    statement = "req.http.host == \"${var.graphql_domain}\""
  }

  condition {
    type      = "RESPONSE"
    name      = "response-graphql-dev"
    statement = "req.http.host == \"${var.graphql_domain}\""
  }

  condition {
    type      = "REQUEST"
    name      = "backend-northstar-dev"
    statement = "req.http.host == \"${var.northstar_domain}\""
  }

  condition {
    type      = "RESPONSE"
    name      = "response-northstar-dev"
    statement = "req.http.host == \"${var.northstar_domain}\""
  }

  condition {
    type      = "REQUEST"
    name      = "backend-phoenix-dev"
    statement = "req.http.host == \"${var.phoenix_domain}\""
  }

  condition {
    type      = "RESPONSE"
    name      = "response-phoenix-dev"
    statement = "req.http.host == \"${var.phoenix_domain}\""
  }

  condition {
    type      = "REQUEST"
    name      = "backend-rogue-dev"
    statement = "req.http.host == \"${var.rogue_domain}\""
  }

  condition {
    type      = "RESPONSE"
    name      = "response-rogue-dev"
    statement = "req.http.host == \"${var.rogue_domain}\""
  }

  condition {
    type      = "REQUEST"
    name      = "path-robots"
    statement = "req.url.basename == \"robots.txt\""
  }

  condition {
    type      = "REQUEST"
    name      = "is-authenticated"
    statement = "req.http.authorization"
  }

  cache_setting {
    name            = "pass-authenticated"
    cache_condition = "is-authenticated"
    action          = "pass"
  }

  backend {
    address           = "${var.graphql_backend}"
    name              = "${var.graphql_name}"
    request_condition = "backend-graphql-dev"
    shield            = "iad-va-us"
    auto_loadbalance  = false
    port              = 443
  }

  backend {
    address           = "${var.northstar_backend}"
    name              = "${var.northstar_name}"
    request_condition = "backend-northstar-dev"
    shield            = "iad-va-us"
    auto_loadbalance  = false
    port              = 443
  }

  backend {
    address           = "${var.phoenix_backend}"
    name              = "${var.phoenix_name}"
    request_condition = "backend-phoenix-dev"
    shield            = "iad-va-us"
    auto_loadbalance  = false
    port              = 443
  }

  backend {
    address           = "${var.rogue_backend}"
    name              = "${var.rogue_name}"
    request_condition = "backend-rogue-dev"
    shield            = "iad-va-us"
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

  papertrail {
    name               = "northstar-dev"
    address            = "${element(split(":", var.papertrail_destination), 0)}"
    port               = "${element(split(":", var.papertrail_destination), 1)}"
    format             = "%t '%r' status=%>s bytes=%b microseconds=%D"
    response_condition = "response-northstar-dev"
  }

  papertrail {
    name               = "phoenix-dev"
    address            = "${element(split(":", var.papertrail_destination), 0)}"
    port               = "${element(split(":", var.papertrail_destination), 1)}"
    format             = "${var.papertrail_log_format}"
    response_condition = "response-phoenix-dev"
  }

  papertrail {
    name               = "rogue-dev"
    address            = "${element(split(":", var.papertrail_destination), 0)}"
    port               = "${element(split(":", var.papertrail_destination), 1)}"
    format             = "${var.papertrail_log_format}"
    response_condition = "response-rogue-dev"
  }

  papertrail {
    name               = "graphql-dev"
    address            = "${element(split(":", var.papertrail_destination), 0)}"
    port               = "${element(split(":", var.papertrail_destination), 1)}"
    format             = "${var.papertrail_log_format}"
    response_condition = "response-graphql-dev"
  }
}

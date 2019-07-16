variable "northstar_name" {}
variable "northstar_domain" {}
variable "northstar_backend" {}
variable "rogue_name" {}
variable "rogue_domain" {}
variable "rogue_backend" {}
variable "papertrail_destination" {}
variable "papertrail_log_format" {}

resource "fastly_service_v1" "backends-qa" {
  name          = "Terraform: Backends (QA)"
  force_destroy = true

  domain {
    name = var.northstar_domain
  }

  domain {
    name = var.rogue_domain
  }

  condition {
    type      = "REQUEST"
    name      = "backend-northstar-qa"
    statement = "req.http.host == \"${var.northstar_domain}\""
  }

  condition {
    type      = "RESPONSE"
    name      = "response-northstar-qa"
    statement = "req.http.host == \"${var.northstar_domain}\""
  }

  condition {
    type      = "REQUEST"
    name      = "backend-rogue-qa"
    statement = "req.http.host == \"${var.rogue_domain}\""
  }

  condition {
    type      = "RESPONSE"
    name      = "response-rogue-qa"
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
    statement = "req.http.Authorization"
  }

  request_setting {
    name              = "pass-authenticated"
    request_condition = "is-authenticated"
    action            = "pass"
  }

  backend {
    address           = var.northstar_backend
    name              = var.northstar_name
    request_condition = "backend-northstar-qa"
    shield            = "iad-va-us"
    auto_loadbalance  = false
    port              = 443
  }

  backend {
    address           = var.rogue_backend
    name              = var.rogue_name
    request_condition = "backend-rogue-qa"
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
    content           = file("${path.root}/shared/deny-robots.txt")
    request_condition = "path-robots"
  }

  snippet {
    name    = "Shared - Set X-Origin-Name Header"
    type    = "fetch"
    content = file("${path.root}/shared/app_name.vcl")
  }

  papertrail {
    name    = "backend"
    address = element(split(":", var.papertrail_destination), 0)
    port    = element(split(":", var.papertrail_destination), 1)
    format  = var.papertrail_log_format
  }
}


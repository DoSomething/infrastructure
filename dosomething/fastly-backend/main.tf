variable "northstar_name" {}
variable "northstar_domain" {}
variable "northstar_backend" {}
variable "phoenix_preview_name" {}
variable "phoenix_preview_domain" {}
variable "phoenix_preview_backend" {}
variable "rogue_name" {}
variable "rogue_domain" {}
variable "rogue_backend" {}
variable "papertrail_destination" {}
variable "papertrail_log_format" {}

locals {
  headers = {
    "X-Fastly-Country-Code" = "client.geo.country_code",
    "X-Fastly-Region-Code"  = "client.geo.region",
    "X-Fastly-Postal-Code"  = "client.geo.postal_code",
  }
}

resource "fastly_service_v1" "backends" {
  name          = "Terraform: Backends"
  force_destroy = true

  domain {
    name = var.northstar_domain
  }

  domain {
    name = var.phoenix_preview_domain
  }

  domain {
    name = var.rogue_domain
  }

  condition {
    type      = "REQUEST"
    name      = "backend-northstar"
    statement = "req.http.host == \"${var.northstar_domain}\""
  }

  condition {
    type      = "RESPONSE"
    name      = "response-northstar"
    statement = "req.http.host == \"${var.northstar_domain}\""
  }

  condition {
    type      = "REQUEST"
    name      = "backend-phoenix-preview"
    statement = "req.http.host == \"${var.phoenix_preview_domain}\""
  }

  condition {
    type      = "RESPONSE"
    name      = "response-phoenix-preview"
    statement = "req.http.host == \"${var.phoenix_preview_domain}\""
  }

  condition {
    type      = "REQUEST"
    name      = "backend-rogue"
    statement = "req.http.host == \"${var.rogue_domain}\""
  }

  condition {
    type      = "RESPONSE"
    name      = "response-rogue"
    statement = "req.http.host == \"${var.rogue_domain}\""
  }

  condition {
    type      = "REQUEST"
    name      = "path-robots-preview"
    statement = "req.url.basename == \"robots.txt\" && req.http.host == \"${var.phoenix_preview_domain}\""
  }

  response_object {
    name              = "robots.txt deny for phoenix-preview"
    content           = file("${path.module}/deny-robots.txt")
    request_condition = "path-robots-preview"
  }

  condition {
    type      = "CACHE"
    name      = "is-not-found"
    statement = "beresp.status == 404"
  }

  cache_setting {
    name            = "pass-not-found"
    cache_condition = "is-not-found"
    action          = "pass"
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
    request_condition = "backend-northstar"
    shield            = "bwi-va-us"
    auto_loadbalance  = false
    port              = 443
  }

  backend {
    address           = var.phoenix_preview_backend
    name              = var.phoenix_preview_name
    request_condition = "backend-phoenix-preview"
    shield            = "bwi-va-us"
    auto_loadbalance  = false
    port              = 443
  }

  backend {
    address           = var.rogue_backend
    name              = var.rogue_name
    request_condition = "backend-rogue"
    shield            = "bwi-va-us"
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

  # Set headers on incoming HTTP requests, for the backend server.
  dynamic "header" {
    for_each = local.headers

    content {
      name        = "${header.key} (Request)"
      destination = "http.${header.key}"
      source      = header.value
      type        = "request"
      action      = "set"
    }
  }

  # And set "debug" headers on HTTP responses, for inspection.
  dynamic "header" {
    for_each = local.headers

    content {
      name        = "${header.key} (Response)"
      destination = "http.${header.key}"
      source      = header.value
      type        = "response"
      action      = "set"
    }
  }

  request_setting {
    name      = "Force SSL"
    force_ssl = true
  }

  snippet {
    name    = "Shared - Set X-Origin-Name Header"
    type    = "fetch"
    content = file("${path.module}/app_name.vcl")
  }

  papertrail {
    name    = "backend"
    address = element(split(":", var.papertrail_destination), 0)
    port    = element(split(":", var.papertrail_destination), 1)
    format  = var.papertrail_log_format
  }
}


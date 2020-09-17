variable "assets_domain" {}
variable "assets_backend" {}
variable "phoenix_name" {}
variable "phoenix_backend" {}
variable "papertrail_destination" {}
variable "papertrail_log_format" {}

locals {
  headers = {
    "X-Fastly-Country-Code" = "client.geo.country_code",
    "X-Fastly-Region-Code"  = "client.geo.region",
    "X-Fastly-Postal-Code"  = "client.geo.postal_code",
  }
}

resource "fastly_service_v1" "frontend" {
  name          = "Terraform: Frontend"
  force_destroy = true

  domain {
    name = "www.dosomething.org"
  }

  domain {
    name = var.assets_domain
  }

  condition {
    type      = "REQUEST"
    name      = "backend-assets"
    statement = "req.http.host == \"${var.assets_domain}\""
  }

  condition {
    type      = "CACHE"
    name      = "cache-assets"
    statement = "req.http.host == \"${var.assets_domain}\""
  }

  backend {
    name              = "s3-assets.dosomething.org"
    address           = var.assets_backend
    request_condition = "backend-assets"
    port              = 80
  }

  backend {
    address          = var.phoenix_backend
    name             = var.phoenix_name
    auto_loadbalance = false
    port             = 443
  }

  condition {
    type = "REQUEST"
    name = "is-authenticated"

    # We want exclude logged-in users from Fastly caching (since their responses will
    # likely include user-specific content) but still cache static assets at the edge.
    statement = "req.http.Cookie ~ \"laravel_session=\" && req.url !~ \"\\.(css|js|woff|otf|ttf|svg)(\\?.*)?$\""
  }

  request_setting {
    name              = "pass-authenticated"
    request_condition = "is-authenticated"
    action            = "pass"
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

  # The S3 backend only returns a 'Vary' header if a request has a CORS header on it, which
  # means we may accidentally cache a CORS-less response for everyone. This rule adds the
  # expected 'Vary' if it isn't already set on the response.
  header {
    name            = "S3 Vary"
    type            = "cache"
    cache_condition = "cache-assets"
    action          = "set"
    destination     = "http.Vary"
    source          = "\"Origin, Access-Control-Request-Headers, Access-Control-Request-Method\""
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
    name    = "ISO-3166-2 Request Header"
    type    = "recv"
    content = file("${path.module}/iso3166_recv.vcl")
  }

  snippet {
    name    = "ISO-3166-2 Response Header"
    type    = "deliver"
    content = file("${path.module}/iso3166_deliver.vcl")
  }

  snippet {
    name    = "Trigger Homepage Redirect"
    type    = "recv"
    content = file("${path.module}/homepage_recv.vcl")
  }

  snippet {
    name    = "Handle Homepage Redirect"
    type    = "error"
    content = file("${path.module}/homepage_error.vcl")
  }

  snippet {
    name    = "Trigger Aurora Redirect"
    type    = "recv"
    content = file("${path.module}/redirect_recv.vcl")

    priority = 10 # Specifying priority so Aurora redirects take precedence.
  }

  snippet {
    name    = "Handle Aurora Redirect"
    type    = "error"
    content = file("${path.module}/redirect_error.vcl")
  }

  snippet {
    name    = "Legacy Paths - Trigger Redirect"
    type    = "recv"
    content = file("${path.module}/legacy_redirects_recv.vcl")
  }

  snippet {
    name    = "Legacy Paths - Handle Redirect"
    type    = "error"
    content = file("${path.module}/legacy_redirects_error.vcl")
  }

  snippet {
    name    = "Shared - Set X-Origin-Name Header"
    type    = "fetch"
    content = file("${path.module}/app_name.vcl")
  }

  papertrail {
    name    = "frontend"
    address = element(split(":", var.papertrail_destination), 0)
    port    = element(split(":", var.papertrail_destination), 1)
    format  = var.papertrail_log_format
  }

  dictionary {
    name = "redirects"
  }
}


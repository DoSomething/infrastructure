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

resource "fastly_service_v1" "frontend-dev" {
  name          = "Terraform: Frontend (Development)"
  force_destroy = true

  domain {
    name = "dev.dosomething.org"
  }

  condition {
    type      = "REQUEST"
    name      = "path-robots"
    statement = "req.url.basename == \"robots.txt\""
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

  // Set headers on incoming HTTP requests, for the backend server.
  dynamic "header" {
    for_each = local.headers

    content {
      name        = header.key
      destination = "http.${header.key}"
      source      = header.value
      type        = "request"
      action      = "set"
    }
  }

  // And set "debug" headers on HTTP responses, for inspection.
  dynamic "header" {
    for_each = local.headers

    content {
      name        = "${header.key} (Debug)"
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

  response_object {
    name              = "robots.txt deny"
    content           = file("${path.root}/shared/deny-robots.txt")
    request_condition = "path-robots"
  }

  snippet {
    name    = "Frontend - Trigger International Redirect"
    type    = "recv"
    content = file("${path.module}/homepage_recv.vcl")
  }

  snippet {
    name    = "Frontend - Handle International Redirect"
    type    = "error"
    content = file("${path.module}/homepage_error.vcl")
  }

  snippet {
    name    = "Frontend - Trigger Redirect"
    type    = "recv"
    content = file("${path.module}/redirect_recv.vcl")

    priority = 10 # Specifying priority so Aurora redirects take precedence.
  }

  snippet {
    name    = "Frontend - Handle Redirect"
    type    = "error"
    content = file("${path.module}/redirect_error.vcl")
  }

  snippet {
    name    = "ProjectPages - Trigger Redirect"
    type    = "recv"
    content = file("${path.module}/legacy_redirects_recv.vcl")
  }

  snippet {
    name    = "ProjectPages - Handle Redirect"
    type    = "error"
    content = file("${path.module}/legacy_redirects_error.vcl")
  }

  snippet {
    name    = "Shared - Set X-Origin-Name Header"
    type    = "fetch"
    content = file("${path.root}/shared/app_name.vcl")
  }

  papertrail {
    name    = "frontend"
    address = element(split(":", var.papertrail_destination), 0)
    port    = element(split(":", var.papertrail_destination), 1)
    format  = var.papertrail_log_format
  }
}


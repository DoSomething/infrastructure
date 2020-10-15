variable "name" {
  description = "The name for this Fastly property."
  type        = string
}

variable "environment" {
  description = "The environment for this property: development, qa, or production."
}

variable "application" {
  description = "The application module to route traffic to."
  type        = object({ name = string, domain = string, backend = string })
}

variable "papertrail_destination" {
  description = "The Papertrail log destination to write logs to."
  type        = string
}

locals {
  request_headers = {
    # Provide geolocation information to web servers:
    "X-Fastly-Country-Code" = "client.geo.country_code",
    "X-Fastly-Region-Code"  = "client.geo.region",
    "X-Fastly-Postal-Code"  = "client.geo.postal_code",
  }

  response_headers = {
    # Expose geolocation information in debug headers:
    "X-Fastly-Country-Code" = "client.geo.country_code",
    "X-Fastly-Region-Code"  = "client.geo.region",
    "X-Fastly-Postal-Code"  = "client.geo.postal_code",

    # Ensures that we don't leak sensitive items from URLs in Referrer headers: we will
    # send full URL if same-origin and HTTPS, origin-only (e.g. 'www.dosomething.org')
    # when crossing domains, and nothing at all when going to HTTP.
    "Referrer-Policy" = "\"strict-origin-when-cross-origin\""

    # Enforce HTTPS for all traffic (TODO: https://www.pivotaltracker.com/story/show/174911098)
    "Strict-Transport-Security" = "\"max-age=604800; includeSubDomains\"" # 1 week.

    # Prevent sniffing content types:
    "X-Content-Type-Options" = "\"nosniff\""

    # Restrict this application from being embedded as an iframe on
    # third-party domains, to prevent click-jacking attacks:
    "X-Frame-Options" = "\"SAMEORIGIN\""

    # Enable XSS filtering in some browsers. This should be
    # replaced by a strong Content Security Policy in the future.
    # TODO: https://www.pivotaltracker.com/story/show/174911196
    "X-XSS-Protection" = "\"1\""
  }
}

resource "fastly_service_v1" "frontend" {
  name          = var.name
  force_destroy = true

  domain {
    name = var.application.domain
  }

  backend {
    address          = var.application.backend
    name             = var.application.name
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

  dynamic "header" {
    for_each = local.request_headers

    content {
      name        = "${header.key} (Request)"
      destination = "http.${header.key}"
      source      = header.value
      type        = "request"
      action      = "set"
    }
  }

  dynamic "header" {
    for_each = local.response_headers

    content {
      name        = "${header.key} (Response)"
      destination = "http.${header.key}"
      source      = header.value
      type        = "response"
      action      = "set"
    }
  }

  # Override: Remove 'X-Frame-Options' on URL(s) that we do
  # want to allow embedding from external domains:
  condition {
    type      = "RESPONSE"
    name      = "allow-embed"
    statement = "req.url ~ \"^/us/about/voter-registration-thank-you\""
  }

  header {
    name               = "Allow Embed on Path(s)"
    type               = "response"
    action             = "delete"
    destination        = "http.X-Frame-Options"
    response_condition = "allow-embed"
    priority           = 200 # This needs to happen after we add the response header, above.
  }

  # Redirect any HTTP traffic to HTTPS:
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

  condition {
    type      = "REQUEST"
    name      = "path-robots"
    statement = "req.url.basename == \"robots.txt\""
  }

  dynamic "response_object" {
    # If we're not in production, add a 'robots.txt' to deny web crawlers.
    for_each = var.environment != "production" ? [1] : []

    content {
      name              = "robots.txt deny"
      content           = file("${path.module}/deny-robots.txt")
      request_condition = "path-robots"
    }
  }

  papertrail {
    name    = "frontend"
    address = element(split(":", var.papertrail_destination), 0)
    port    = element(split(":", var.papertrail_destination), 1)
    format  = "%t '%r' status=%>s app=%%{X-Application-Name}o cache=\"%%{X-Cache}o\" country=%%{X-Fastly-Country-Code}o ip=\"%a\" user-agent=\"%%{User-Agent}i\" service=%%{time.elapsed.msec}Vms"
  }

  dictionary {
    name = "redirects"
  }
}


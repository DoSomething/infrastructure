variable "name" {
  description = "The name for this Fastly property."
  type        = string
}

variable "backends" {
  description = "The domains/backends to route traffic to in this property."
  type        = list(object({ name = string, domain = string, backend = string }))
}

variable "papertrail_destination" {
  description = "The Papertrail log destination to write logs to."
  type        = string
}

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

  # Configure backend, domain, and condition for each app:
  dynamic "domain" {
    for_each = var.backends

    content {
      name = domain.value.domain
    }
  }

  dynamic "condition" {
    for_each = var.backends

    content {
      type      = "RESPONSE"
      name      = "response-${condition.value.name}"
      statement = "req.http.host == \"${condition.value.domain}\""
    }
  }

  dynamic "condition" {
    for_each = var.backends

    content {
      type      = "REQUEST"
      name      = "backend-${condition.value.name}"
      statement = "req.http.host == \"${condition.value.domain}\""
    }
  }

  dynamic "backend" {
    for_each = var.backends

    content {
      address           = backend.value.backend
      name              = backend.value.name
      request_condition = "backend-${backend.value.name}" # defined above.
      port              = 443

      # We use shielding to increase chances that we get cache hits. We don't rely
      # on Fastly for load balancing (since that is handled by Heroku's router).
      shield           = "bwi-va-us"
      auto_loadbalance = false
    }
  }

  # Fix issue with geolocation when shielding is enabled:
  snippet {
    name    = "Fix Geolocation With Shielding On"
    type    = "recv"
    content = file("${path.module}/recv_geolocation.vcl")
  }

  # Configure 'robots.txt' global deny for backends:
  condition {
    type      = "REQUEST"
    name      = "path-robots"
    statement = "req.url.basename == \"robots.txt\""
  }

  response_object {
    name              = "robots.txt deny"
    content           = file("${path.module}/deny-robots.txt")
    request_condition = "path-robots"
  }

  # Do not cache 'not found' & authenticated requests:
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

  # Enable GZIP to make things speedy!
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

  # Force SSL at the edge:
  request_setting {
    name      = "Force SSL"
    force_ssl = true
  }

  # Set an 'X-Origin-Name' header for debugging & for logging to Papertrail:
  snippet {
    name    = "Shared - Set X-Origin-Name Header"
    type    = "fetch"
    content = file("${path.module}/app_name.vcl")
  }

  # Write requests to this Fastly property to the provided Papertrail drain:
  papertrail {
    name    = "backend"
    address = element(split(":", var.papertrail_destination), 0)
    port    = element(split(":", var.papertrail_destination), 1)
    format  = "%t '%r' status=%>s app=%%{X-Application-Name}o cache=\"%%{X-Cache}o\" country=%%{X-Fastly-Country-Code}o ip=\"%a\" user-agent=\"%%{User-Agent}i\" service=%%{time.elapsed.msec}Vms"
  }
}

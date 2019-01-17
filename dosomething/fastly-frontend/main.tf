variable "ashes_backend" {}
variable "phoenix_name" {}
variable "phoenix_backend" {}
variable "papertrail_destination" {}

resource "fastly_service_v1" "frontend" {
  name          = "Terraform: Frontend"
  force_destroy = true

  domain {
    name = "www.dosomething.org"
  }

  condition {
    type = "REQUEST"
    name = "backend-ashes"

    # See 'ashes_recv.vcl' for where this is set.
    statement = "req.http.X-Fastly-Backend == \"ashes\""
  }

  condition {
    type      = "REQUEST"
    name      = "timed-synthetic-takeover"
    statement = "req.http.X-Timed-Synthetic-Response == \"true\""
  }

  response_object {
    name              = "timed synthetic takeover"
    request_condition = "timed-synthetic-takeover"
    content           = "${file("${path.root}/shared/takeovers/election.html")}"
  }

  backend {
    address           = "${var.ashes_backend}"
    name              = "ashes"
    request_condition = "backend-ashes"
    ssl_cert_hostname = "www.dosomething.org"
    ssl_sni_hostname  = "www.dosomething.org"
    auto_loadbalance  = false
    use_ssl           = true
    port              = 443
  }

  backend {
    address          = "${var.phoenix_backend}"
    name             = "${var.phoenix_name}"
    auto_loadbalance = false
    port             = 443
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

  snippet {
    name    = "Frontend - Ashes Routing"
    type    = "recv"
    content = "${file("${path.module}/ashes_recv.vcl")}"
  }

  snippet {
    name    = "Frontend - Trigger International Redirect"
    type    = "recv"
    content = "${file("${path.module}/homepage_recv.vcl")}"
  }

  snippet {
    name    = "Frontend - Handle International Redirect"
    type    = "error"
    content = "${file("${path.module}/homepage_error.vcl")}"
  }

  snippet {
    name    = "Frontend - Trigger Redirect"
    type    = "recv"
    content = "${file("${path.module}/redirect_recv.vcl")}"
  }

  snippet {
    name    = "Frontend - Handle Redirect"
    type    = "error"
    content = "${file("${path.module}/redirect_error.vcl")}"
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

  snippet {
    name    = "Frontend - Homepage Takeover Configuration"
    type    = "recv"
    content = "${file("${path.module}/takeover_config.vcl")}"

    priority = 0 # Make sure we configure this before it runs below!
  }

  snippet {
    name    = "Shared - Static Homepage Takeover"
    type    = "recv"
    content = "${file("${path.root}/shared/takeover_recv.vcl")}"
  }

  papertrail {
    name    = "www.dosomething.org"
    address = "${element(split(":", var.papertrail_destination), 0)}"
    port    = "${element(split(":", var.papertrail_destination), 1)}"
    format  = "%t '%r' status=%>s backend=%{X-Origin-Name}o microseconds=%D"
  }
}

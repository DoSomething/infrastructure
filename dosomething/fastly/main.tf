variable "graphql_name" {}
variable "graphql_domain" {}
variable "graphql_backend" {}
variable "northstar_name" {}
variable "northstar_domain" {}
variable "northstar_backend" {}
variable "papertrail_destination" {}

resource "fastly_service_v1" "dosomething" {
  name          = "Terraform: DoSomething"
  force_destroy = true

  domain {
    name = "${var.graphql_domain}"
  }

  domain {
    name = "${var.northstar_domain}"
  }

  condition {
    type      = "REQUEST"
    name      = "backend-graphql"
    statement = "req.http.host == \"${var.graphql_domain}\""
  }

  condition {
    type      = "REQUEST"
    name      = "backend-northstar"
    statement = "req.http.host == \"${var.northstar_domain}\""
  }

  backend {
    address           = "${var.graphql_backend}"
    name              = "${var.graphql_name}"
    request_condition = "backend-graphql"
    port              = 443
  }

  backend {
    address           = "${var.northstar_backend}"
    name              = "${var.northstar_name}"
    request_condition = "backend-northstar"
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

  request_setting {
    name      = "Force SSL"
    force_ssl = true
  }

  vcl {
    main = true
    name = "main"

    # @TODO: Separate into snippets once Terraform adds support.
    content = "${file("${path.module}/custom.vcl")}"
  }

  condition {
    type      = "RESPONSE"
    name      = "errors-northstar"
    statement = "req.http.host == \"${var.northstar_domain}\" && resp.status > 501 && resp.status < 600"
  }

  papertrail {
    name               = "northstar"
    address            = "${element(split(":", var.papertrail_destination), 0)}"
    port               = "${element(split(":", var.papertrail_destination), 1)}"
    format             = "%t '%r' status=%>s bytes=%b microseconds=%D"
    response_condition = "errors-northstar"
  }
}

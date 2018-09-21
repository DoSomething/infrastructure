resource "fastly_service_v1" "vote" {
  name          = "Terraform: Voter Registration"
  force_destroy = true

  domain {
    name = "vote-fastly.dosomething.org"
  }

  default_host = "vote.dosomething.org"

  backend {
    name    = "instapage"
    address = "secure.pageserve.co"
    port    = 80
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

  vcl {
    main = true
    name = "main"

    # @TODO: Separate into snippets once Terraform adds support.
    content = "${file("${path.module}/custom.vcl")}"
  }
}

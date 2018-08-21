provider "fastly" {
  version = "~> 0.3"
}

resource "fastly_service_v1" "misc" {
  name = "Terraform: Miscellaneous"

  domain {
    name = "api.dosomething.org"
  }

  # Note: Fastly requires at least one backend per service,
  # so our AWS HAProxy instance is included here.
  backend {
    address = "54.172.90.245"
    name = "HAProxy"
    port = 80
  }

  vcl {
    main = true
    name = "misc"
    # @TODO: Separate into snippets once Terraform adds support.
    content = "${file("vcl/misc.vcl")}"
  }
}

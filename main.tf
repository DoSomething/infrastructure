resource "fastly_service_v1" "misc" {
  name = "Terraform: Miscellaneous"

  domain {
    name = "api.dosomething.org"
  }

  vcl {
    main = true
    name = "misc"
    # @TODO: Separate into snippets once Terraform adds support.
    content = "${file("vcl/misc.vcl")}"
  }
}

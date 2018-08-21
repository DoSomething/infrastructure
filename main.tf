resource "fastly_service_v1" "misc" {
  name = "Terraform: Miscellaneous"

  domain {
    name = "api.dosomething.org"
  }
}

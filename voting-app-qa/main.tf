resource "fastly_service_v1" "voting-app-qa" {
  name = "Terraform: Voting App (QA)"
  force_destroy = true

  domain {
    name = "www.catsgonegood.com"
  }

  backend {
    address = "54.172.90.245"
    name = "HAProxy"
    port = 80
  }

  header {
    name = "Country Code"
    type = "request"
    action = "set"
    source = "geoip.country_code"
    destination = "http.X-Fastly-Country-Code"
  }

  header {
    name = "Country Code (Debug)"
    type = "response"
    action = "set"
    source = "geoip.country_code"
    destination = "http.X-Fastly-Country-Code"
  }
}

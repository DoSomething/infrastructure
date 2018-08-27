resource "fastly_service_v1" "voting-app" {
  name          = "Terraform: Voting App"
  force_destroy = true

  domain {
    name = "www.celebsgonegood.com"
  }

  domain {
    name = "www.athletesgonegood.com"
  }

  domain {
    name = "www.fourleggedfinishers.com"
  }

  backend {
    address = "54.172.90.245"
    name    = "HAProxy"
    port    = 80
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
}

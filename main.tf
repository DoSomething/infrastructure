provider "fastly" {
  version = "~> 0.3"
}

resource "fastly_service_v1" "voting-app" {
  name = "Terraform: Voting App"

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

resource "fastly_service_v1" "voting-app-qa" {
  name = "Terraform: Voting App (QA)"

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

resource "fastly_service_v1" "misc" {
  name = "Terraform: Miscellaneous"

  domain {
    name = "api.dosomething.org"
  }

  domain {
    name = "northstar.dosomething.org"
  }

  domain {
    name = "northstar-thor.dosomething.org"
  }

  domain {
    name = "northstar-qa.dosomething.org"
  }

  domain {
    name = "profile.dosomething.org"
  }

  domain {
    name = "rogue.dosomething.org"
  }

  domain {
    name = "rogue-thor.dosomething.org"
  }

  domain {
    name = "rogue-qa.dosomething.org"
  }

  domain {
    name = "aurora.dosomething.org"
  }

  domain {
    name = "aurora-thor.dosomething.org"
  }

  domain {
    name = "aurora-qa.dosomething.org"
  }

  domain {
    name = "data.dosomething.org"
  }

  domain {
    name = "www.teensforjeans.com"
  }

  domain {
    name = "www.dosomethingtote.org"
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

variable "fastly_api_key" {}

terraform {
  backend "remote" {
    organization = "dosomething"

    workspaces {
      name = "redirects"
    }
  }
}

provider "fastly" {
  version = "0.9.0"
  api_key = var.fastly_api_key
}

resource "fastly_service_v1" "redirects" {
  name          = "Terraform: Domain Redirects, #1"
  force_destroy = true

  #
  # We primarily use this property for domain redirects, like going from
  # www.oldsite.com/any-path to www.newsite.com/any-path. To add a new
  # domain, first add the origin domain to Fastly below. Then, head into
  # 'misc.vcl' and add the mapping for how it should redirect!
  #
  # NOTE: Fastly allows a maximum of 20 domains per service, so if this
  # service is full, scroll down to `redirects2` below!
  #
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
    name = "thor.dosomething.org"
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

  domain {
    name = "www.fourleggedfinishers.com"
  }

  domain {
    name = "www.fourleggedfinishers.org"
  }

  domain {
    name = "www.catsgonegood.com"
  }

  domain {
    name = "phoenix-preview.dosomething.org"
  }

  domain {
    name = "redirect.dosomething.org"
  }

  # Note: Fastly requires at least one backend per service,
  # so our AWS HAProxy instance is included here.
  backend {
    address = "54.172.90.245"
    name    = "HAProxy"
    port    = 80
  }

  snippet {
    name    = "Redirects Table"
    type    = "init"
    content = file("${path.module}/redirects_table.vcl")
  }

  snippet {
    name    = "Trigger Redirect"
    type    = "recv"
    content = file("${path.module}/trigger_redirect.vcl")
  }

  snippet {
    name    = "Handle Redirect"
    type    = "error"
    content = file("${path.module}/handle_redirect.vcl")
  }
}

resource "fastly_service_v1" "redirects2" {
  name          = "Terraform: Domain Redirects, #2"
  force_destroy = true

  #
  # We primarily use this property for domain redirects, like going from
  # www.oldsite.com/any-path to www.newsite.com/any-path. To add a new
  # domain, first add the origin domain to Fastly below. Then, head into
  # 'misc.vcl' and add the mapping for how it should redirect!
  #
  domain {
    name = "canada.dosomething.org"
  }

  domain {
    name = "uk.dosomething.org"
  }

  domain {
    name = "m.dosomething.org"
  }

  domain {
    name = "files.dosomething.org"
  }

  domain {
    name = "beta.dosomething.org"
  }

  domain {
    name = "www-dev.dosomething.org"
  }

  domain {
    name = "www-preview.dosomething.org"
  }

  domain {
    name = "activity.dosomething.org"
  }

  domain {
    name = "activity-qa.dosomething.org"
  }

  domain {
    name = "activity-dev.dosomething.org"
  }

  domain {
    name = "admin.dosomething.org"
  }

  domain {
    name = "admin-qa.dosomething.org"
  }

  domain {
    name = "admin-dev.dosomething.org"
  }

  # Note: Fastly requires at least one backend per service,
  # so our AWS HAProxy instance is included here.
  backend {
    address = "54.172.90.245"
    name    = "HAProxy"
    port    = 80
  }

  snippet {
    name    = "Redirects Table"
    type    = "init"
    content = file("${path.module}/redirects_table.vcl")
  }

  snippet {
    name    = "Trigger Redirect"
    type    = "recv"
    content = file("${path.module}/trigger_redirect.vcl")
  }

  snippet {
    name    = "Handle Redirect"
    type    = "error"
    content = file("${path.module}/handle_redirect.vcl")
  }
}


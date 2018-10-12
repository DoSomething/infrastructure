resource "fastly_service_v1" "redirects" {
  name          = "Terraform: Domain Redirects"
  force_destroy = true

  #
  # We primarily use this property for domain redirects, like going from
  # www.oldsite.com/any-path to www.newsite.com/any-path. To add a new
  # domain, first add the origin domain to Fastly below. Then, head into
  # 'misc.vcl' and add the mapping for how it should redirect!
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
    content = "${file("${path.module}/redirects_table.vcl")}"
  }

  snippet {
    name    = "Trigger Redirect"
    type    = "recv"
    content = "${file("${path.module}/trigger_redirect.vcl")}"
  }

  snippet {
    name    = "Handle Redirect"
    type    = "error"
    content = "${file("${path.module}/handle_redirect.vcl")}"
  }
}

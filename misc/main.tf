resource "fastly_service_v1" "misc" {
  name          = "Terraform: Miscellaneous"
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

  # Note: Fastly requires at least one backend per service,
  # so our AWS HAProxy instance is included here.
  backend {
    address = "54.172.90.245"
    name    = "HAProxy"
    port    = 80
  }

  vcl {
    main = true
    name = "misc"

    # @TODO: Separate into snippets once Terraform adds support.
    content = "${file("${path.module}/misc.vcl")}"
  }
}

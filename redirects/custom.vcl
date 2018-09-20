#
# This is a custom VCL for this property, since Terraform does
# not support Fastly's VCL snippets yet. <https://git.io/fAU5g> 
# 
# See Fastly's VCL boilerplate & documentation here:
# <https://docs.fastly.com/vcl/custom-vcl/creating-custom-vcl/>
#

# ------------------------------------------------------------------------------------
# Snippet: Redirects (INIT)
# ------------------------------------------------------------------------------------
#
# This is where we define domain redirects! (See the "Trigger Redirect" and "Handle
# Redirect" snippets below). To redirect a new domain, add the *origin* hostname
# on the left (where you're redirecting from), and the new URL (with protocol)
# on the right!
#
# Pro-tip: To ignore paths on a redirect (e.g. www.old.com/path to new.com/),
# end the "destination" URL with a hash! When redirected, the original path
# will be ignored by the destination web server! :)
#
table redirects {
  # Aurora:
  "aurora.dosomething.org": "https://admin.dosomething.org",
  "aurora-thor.dosomething.org": "https://admin-qa.dosomething.org",
  "aurora-qa.dosomething.org": "https://admin-dev.dosomething.org",
  "redirect.dosomething.org": "https://admin.dosomething.org",

  # Data:
  "data.dosomething.org": "https://dsdata.looker.com",

  # Northstar:
  "northstar.dosomething.org": "https://identity.dosomething.org",
  "northstar-thor.dosomething.org": "https://identity-qa.dosomething.org",
  "northstar-qa.dosomething.org": "https://identity-dev.dosomething.org",
  "profile.dosomething.org": "https://identity.dosomething.org",

  # Phoenix:
  "phoenix-preview.dosomething.org": "https://www-preview.dosomething.org",

  # Rogue:
  "rogue.dosomething.org": "https://activity.dosomething.org",
  "rogue-thor.dosomething.org": "https://activity-qa.dosomething.org",
  "rogue-qa.dosomething.org": "https://activity-dev.dosomething.org",
  
  # etc:
  "api.dosomething.org": "https://graphql.dosomething.org",
  "www.teensforjeans.com": "https://www.dosomething.org/us/campaigns/teens-jeans",
  "www.dosomethingtote.org": "https://www.dosomething.org",
  "www.fourleggedfinishers.com": "https://www.dosomething.org/us/campaigns/four-legged-finishers#",
  "www.fourleggedfinishers.org": "https://www.dosomething.org/us/campaigns/four-legged-finishers#",
  "www.catsgonegood.com": "https://www.celebsgonegood.com",
}
# ------------------------------------------------------------------------------------



sub vcl_recv {
#FASTLY recv
  # ------------------------------------------------------------------------------------
  # Snippet: Trigger Redirect (RECV)
  # ------------------------------------------------------------------------------------
  if(table.lookup(redirects, req.http.host)) {
    error 811;
  }
  # ------------------------------------------------------------------------------------

  if (req.request != "HEAD" && req.request != "GET" && req.request != "FASTLYPURGE") {
    return(pass);
  }

  return(lookup);
}

sub vcl_fetch {
#FASTLY fetch
  if ((beresp.status == 500 || beresp.status == 503) && req.restarts < 1 && (req.request == "GET" || req.request == "HEAD")) {
    restart;
  }

  if (req.restarts > 0) {
    set beresp.http.Fastly-Restarts = req.restarts;
  }

  if (beresp.http.Set-Cookie) {
    set req.http.Fastly-Cachetype = "SETCOOKIE";
    return(pass);
  }

  if (beresp.http.Cache-Control ~ "private") {
    set req.http.Fastly-Cachetype = "PRIVATE";
    return(pass);
  }

  if (beresp.status == 500 || beresp.status == 503) {
    set req.http.Fastly-Cachetype = "ERROR";
    set beresp.ttl = 1s;
    set beresp.grace = 5s;
    return(deliver);
  }

  if (beresp.http.Expires || beresp.http.Surrogate-Control ~ "max-age" || beresp.http.Cache-Control ~ "(s-maxage|max-age)") {
    # keep the ttl here
  } else {
    # apply the default ttl
    set beresp.ttl = 3600s;
  }

  return(deliver);
}

sub vcl_hit {
#FASTLY hit

  if (!obj.cacheable) {
    return(pass);
  }
  return(deliver);
}

sub vcl_miss {
#FASTLY miss
  return(fetch);
}

sub vcl_deliver {
#FASTLY deliver
  return(deliver);
}

sub vcl_error {
#FASTLY error
  # ------------------------------------------------------------------------------------
  # Snippet: Handle Redirect (ERROR)
  # ------------------------------------------------------------------------------------
  if (obj.status == 811) {
    set obj.status = 302;
    set obj.http.Location = table.lookup(redirects, req.http.host) + req.url;
    set obj.response = "Found";

    return (deliver);
  }
  # ------------------------------------------------------------------------------------
}

sub vcl_pass {
#FASTLY pass
}

sub vcl_log {
#FASTLY log
}

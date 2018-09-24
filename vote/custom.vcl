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
table redirects {
  # example redirect. format: path -> target URL
  "/direct": "https://register.rockthevote.com/registrants/new?partner=37187&source=[r]",

  # partner/ad direct redirects <https://goo.gl/LKPofK>:
  "/katiecouric": "https://register.rockthevote.com/registrants/new?partner=37187&source=campaignID:8017,campaignRunID:8022,source:influencer,source_details:katie_couric"
  # "/g/1": "https://register.rockthevote.com/registrants/new?partner=37187&source=ads",
  # "/g/2": "https://register.rockthevote.com/registrants/new?partner=37187&source=ads",
  # "/f/1": "https://register.rockthevote.com/registrants/new?partner=37187",
  # "/s/1": "https://register.rockthevote.com/registrants/new?partner=37187",
  # "/nationalschoolwalkout": "https://register.rockthevote.com/registrants/new?partner=37187&source=campaignID:8017,campaignRunID:8022,source:partner,source_details:NSW",
  # "/dmv": "https://register.rockthevote.com/registrants/new?partner=37187&source=campaignID:8017,campaignRunID:8022,source:partner,source_details:dmv_email",
  # "/johnlegend": "https://register.rockthevote.com/registrants/new?partner=37187&source=campaignID:8017,campaignRunID:8022,source:influencer,source_details:john_legend",
  # "/ehjovan": "https://register.rockthevote.com/registrants/new?partner=37187&source=campaignID:8017,campaignRunID:8022,source:influencer,source_details:jovan",
}

sub vcl_recv {
#FASTLY recv
  # ------------------------------------------------------------------------------------
  # Snippet: Trigger Redirects
  # ------------------------------------------------------------------------------------
  if (table.lookup(redirects, std.tolower(req.url.path))) {
    error 700 "Moved";
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
  if (obj.status == 700) {
    declare local var.new_location STRING;
    
    set var.new_location = table.lookup(redirects, std.tolower(req.url.path));
    if (subfield(req.url.qs, "r", "&"))  {
      set var.new_location = regsub(var.new_location, "\[r\]", subfield(req.url.qs, "r", "&"));
    }
    
    set obj.http.Location = var.new_location;
    set obj.status = 302;
  
    return(deliver);
  }
  # ------------------------------------------------------------------------------------
}

sub vcl_pass {
#FASTLY pass
}

sub vcl_log {
#FASTLY log
}

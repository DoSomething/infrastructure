#
# This is a custom VCL for this property, since Terraform does
# not support Fastly's VCL snippets yet. <https://git.io/fAU5g> 
# 
# See Fastly's VCL boilerplate & documentation here:
# <https://docs.fastly.com/vcl/custom-vcl/creating-custom-vcl/>
#

# ------------------------------------------------------------------------------------
# Snippet: EEA Country Codes (INIT)
# ------------------------------------------------------------------------------------
table eea {
  "AT": "true",
  "BE": "true",
  "BG": "true",
  "HR": "true",
  "CY": "true",
  "CZ": "true",
  "DK": "true",
  "EU": "true",
  "EE": "true",
  "FI": "true",
  "FR": "true",
  "DE": "true",
  "GR": "true",
  "HU": "true",
  "IS": "true",
  "IE": "true",
  "IT": "true",
  "LV": "true",
  "LI": "true",
  "LT": "true",
  "LU": "true",
  "MT": "true",
  "NL": "true",
  "NO": "true",
  "PL": "true",
  "PT": "true",
  "RO": "true",
  "SK": "true",
  "SI": "true",
  "ES": "true",
  "SE": "true",
  "CH": "true",
  "UK": "true",
  "GB": "true"
}
# ------------------------------------------------------------------------------------



sub vcl_recv {
#FASTLY recv
  # ------------------------------------------------------------------------------------
  # Snippet: Trigger GDPR Redirect (RECV)
  # ------------------------------------------------------------------------------------
  if (table.lookup(eea, geoip.country_code)) {
    set req.http.X-Fastly-Is-EEA = "true";
    unset req.http.X-Forwarded-For;
    remove req.http.Cookie;
    error 811;
  } else {
    set req.http.X-Fastly-Is-EEA = "false";
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
    set obj.http.Location = "https://sorry.dosomething.org";
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

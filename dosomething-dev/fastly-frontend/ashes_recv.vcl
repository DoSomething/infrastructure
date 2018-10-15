# We can't directly set req.backend here because it's reset
# by Fastly's default VCL just afterwards. Instead we'll set
# a custom header and use that in a request condition.

# Ensure this value is only set within our VCL:
unset req.http.X-Fastly-Backend;

# Should this page be served by Ashes? Let's see:
if (req.url ~ "^\/((us|mx|br)\/?)?$") {
  # The homepage & international variants are served by Ashes:
  set req.http.X-Fastly-Backend = "ashes";
}
else if (req.url ~ "^\/((us|mx|br)\/?)?campaigns\/?$") {
  # The Explore Campaigns page is served by Ashes:
  set req.http.X-Fastly-Backend = "ashes";
}
else if (req.url ~ "\/((us|mx|br)\/)?(admin|openid\-connect|file|sites|profiles|misc|user|taxonomy|modules|search|system|themes|node|js)") {
  # Drupal built-in and third-party modules are served by Ashes:
  set req.http.X-Fastly-Backend = "ashes";
}
else if (req.url ~ "\/((us|mx|br)\/)?(facts|about|sobre|volunteer|voluntario|reportback|ds\-share\-complete|api\/v1)") {
  # And some custom Ashes paths that we've created ourselves:
  set req.http.X-Fastly-Backend = "ashes";
}
else if (req.url ~ "\/((us|mx|br)\/)?campaigns/([A-Za-z0-9_\-]+)" &&
    table.lookup(ashes_campaigns, re.group.3)) {
  # Finally, see if a given campaign should be served by Ashes:
  set req.http.X-Fastly-Backend = "ashes";
}

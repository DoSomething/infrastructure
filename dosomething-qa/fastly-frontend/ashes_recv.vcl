# We can't directly set req.backend here because it's reset
# by Fastly's default VCL just afterwards. Instead we'll set
# a custom header and use that in a request condition.

# Ensure this value is only set within our VCL:
unset req.http.X-Fastly-Backend;

# Should this page be served by Ashes? Let's see:
if (req.url.path ~ "(?i)^\/((us|mx|br)\/?)?$") {
  # The homepage & international variants are served by Ashes:
  set req.http.X-Fastly-Backend = "ashes";
}
else if (req.url.path ~ "(?i)^\/((us|mx|br)\/?)?campaigns\/?$") {
  # The Explore Campaigns page is served by Ashes:
  set req.http.X-Fastly-Backend = "ashes";
}
else if (req.url.path ~ "(?i)^\/index\.php$") {
  # The '/index.php' file is used by some Ashes admin pages:
  set req.http.X-Fastly-Backend = "ashes";
}
else if (req.url.path ~ "(?i)\/((us|mx|br)\/)?(admin|image|openid\-connect|file|sites|profiles|misc|user|taxonomy|modules|search|system|themes|node|js)") {
  # Drupal built-in and third-party modules are served by Ashes:
  set req.http.X-Fastly-Backend = "ashes";
}
else if (
  req.url.path ~ "(?i)\/((us|mx|br)\/)?(facts|fact|about|sobre|volunteer|voluntario|reportback|ds\-share\-complete|api\/v1)"
  && std.tolower(req.url.path) != "/us/about/our-press"
) {
  # And our custom Ashes paths for DS.org content.
  # NOTE: We've specifically overridden 'our-press' to Phoenix!
  set req.http.X-Fastly-Backend = "ashes";
}
else if (req.url.path ~ "(?i)\/((us|mx|br)\/)?campaigns/([A-Za-z0-9_\-]+)" &&
    table.lookup(ashes_campaigns, std.tolower(re.group.3))) {
  # See if a given campaign should be served by Ashes:
  set req.http.X-Fastly-Backend = "ashes";
}

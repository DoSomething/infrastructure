# We can't directly set req.backend here because it's reset
# by Fastly's default VCL just afterwards. Instead we'll set
# a custom header and use that in a request condition.

# Ensure this value is only set within our VCL:
unset req.http.X-Fastly-Backend;

# Should this page be served by Ashes? Let's see:
if (req.url.path ~ "(?i)^\/((mx|br)\/?)?$") {
  # The international homepages are served by Ashes:
  set req.http.X-Fastly-Backend = "ashes";
}
else if (req.url.path ~ "(?i)^\/((mx|br)\/?)?campaigns\/?$") {
  # The Mexican/Brazilian Explore Campaigns page is served by Ashes:
  set req.http.X-Fastly-Backend = "ashes";
}
else if (req.url.path ~ "(?i)^\/index\.php$") {
  # The '/index.php' file is used by some Ashes admin pages:
  set req.http.X-Fastly-Backend = "ashes";
}
else if (req.url.path ~ "(?i)\/((us|mx|br)\/)?(admin|batch|image|openid\-connect|file|sites|profiles|misc|user|taxonomy|modules|search|system|themes|node|js)") {
  # Drupal built-in and third-party modules are served by Ashes:
  set req.http.X-Fastly-Backend = "ashes";
}
else if (req.url.path ~ "(?i)\/((us|mx|br)\/)?(fact|sobre|volunteer|voluntario|reportback|ds\-share\-complete|api\/v1)\/") {
  # And our custom Ashes paths for DS.org content.
  set req.http.X-Fastly-Backend = "ashes";
}
else if (req.url.path ~ "(?i)^\/robots\.txt") {
  # Finally, serve robots.txt from Ashes on production:
  set req.http.X-Fastly-Backend = "ashes";
}

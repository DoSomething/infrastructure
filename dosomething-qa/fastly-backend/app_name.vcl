# Mark which backend is serving the request on a header. (Or forward
# along the name of the backend if this is running on a shield node.)
# This is handy for debugging & logged in Papertrail. <goo.gl/TWF4kz>
if (! beresp.http.X-Application-Name) {
  declare local var.application_name STRING;

  # Remove unhelpful internal Fastly identifier.
  set var.application_name = regsub(beresp.backend.name, "^(.*)--", "");

  # Format header by our convention (e.g. "F_dosomething_phoenix" to "dosomething-phoenix"):
  set beresp.http.X-Application-Name = regsuball(regsub(var.application_name, "F_", ""), "_", "-");
}


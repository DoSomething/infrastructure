# Mark which backend is serving the request on a header. (Or forward
# along the name of the backend if this is running on a shield node.)
# This is handy for debugging & logged in Papertrail. <goo.gl/TWF4kz>
if (! beresp.http.X-Application-Name) {
  set beresp.http.X-Application-Name = regsub(beresp.backend.name, "^(.*)--", "");
}

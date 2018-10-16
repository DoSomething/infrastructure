# Mark which backend is serving the request on a response header.
# This is handy for debugging & logged in Papertrail. <goo.gl/TWF4kz>
set beresp.http.X-Origin-Name = regsub(beresp.backend.name, "^(.*)--", "");

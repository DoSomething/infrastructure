# Handle a redirect error code (see `trigger_redirect.vcl`) to return a 302
# response to send the user to the same URL on the destination domain.
if (obj.status == 811) {
  set obj.status = 302;
  set obj.http.Location = table.lookup(redirects, req.http.host) + req.url;
  set obj.response = "Found";

  return (deliver);
}

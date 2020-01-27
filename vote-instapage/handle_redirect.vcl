# Handle a redirect error code (see `trigger_redirect.vcl`) to return a 302
# response to send the user to the same URL on the destination domain.
if (obj.status == 700) {
  declare local var.new_location STRING;

  # If the destination URL includes a `[r]` token, then place the contents of
  # the origin's `?r=...` query string there so we can maintain tracking.
  set var.new_location = table.lookup(redirects, std.tolower(req.url.path));
  if (subfield(req.url.qs, "r", "&"))  {
    set var.new_location = regsub(var.new_location, "\[r\]", subfield(req.url.qs, "r", "&"));
  }

  set obj.http.Location = var.new_location;
  set obj.status = 302;

  return(deliver);
}

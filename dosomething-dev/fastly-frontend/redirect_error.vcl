# Handle a redirect (see `redirect_recv.vcl`):
if (obj.status == 777) {
  declare local var.new_location STRING;
  set var.new_location = table.lookup(redirects, std.tolower(req.url.path));

  # Forward along query string if we have one:
  if (req.url.qs != "")  {
    set var.new_location = var.new_location + "?" + req.url.qs;
  }

  set obj.http.Location = var.new_location;
  set obj.status = std.atoi(table.lookup(redirect_types, req.url, "302"));

  return(deliver);
}

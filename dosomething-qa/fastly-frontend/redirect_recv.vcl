# Check if we have a redirect stored for this path. Redirects
# are managed in the 'redirects' edge-dictionary via Aurora:
if (table.lookup(redirects, std.tolower(req.url.path))) {
  error 777 "Moved";
}

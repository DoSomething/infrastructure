# If the redirect is found in the redirects table (see `redirects_table.vcl`)
# then trigger an error code so we can redirect (see `handle_redirect.vcl`).
if (table.lookup(redirects, std.tolower(req.url.path))) {
  error 700 "Moved";
}

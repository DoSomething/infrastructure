# Catch any home page request, including those with query strings or hashes.
if (req.url ~ "^/([\?#].+)?$") {
  error 778 "Moved";
}

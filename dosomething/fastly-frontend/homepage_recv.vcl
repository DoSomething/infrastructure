# Catch any home page request, including those with query strings or hashes.
# Pass through only if the user is in MX or BR, where Ashes handles properly.
if (req.url ~ "^/([\?#].+)?$" && geoip.country_code != "MX" && geoip.country_code != "BR") {
  error 778 "Moved";
}

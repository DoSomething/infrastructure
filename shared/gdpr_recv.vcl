// If the current request is coming from a country in the EEA (and is not a
// search or social metadata crawler), trigger a redirect to our GDPR page.
if (table.lookup(eea, geoip.country_code) &&
  req.http.User-Agent !~ "(?i)googlebot|facebot|facebookexternalhit|twitterbot") {
  error 811;
}

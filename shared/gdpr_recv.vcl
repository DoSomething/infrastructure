// If the current request is coming from a country in
// the EEA, trigger a redirect to our GDPR page.
if (table.lookup(eea, geoip.country_code)) {
  error 811;
}

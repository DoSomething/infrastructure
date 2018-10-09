if (table.lookup(eea, geoip.country_code)) {
  set req.http.X-Fastly-Is-EEA = "true";
  unset req.http.X-Forwarded-For;
  remove req.http.Cookie;
  error 811;
} else {
  set req.http.X-Fastly-Is-EEA = "false";
}

// Are were able to determine a country code? (If not, value is "**"):
if (client.geo.country_code != "**") {
  // US Territories should be stored as regions under 'US-'. <https://goo.gl/qzcMyb>
  if (client.geo.country_code ~ "AS|GU|MP|PR|UM|VI") {
    set resp.http.X-Fastly-Location-Code = "US-" + client.geo.country_code;
  }
  // Otherwise, were we able to determine a region? (If not, value is "NO REGION" or "?"):
  else if (client.geo.region != "NO REGION" && client.geo.region != "?") {
    set resp.http.X-Fastly-Location-Code = client.geo.country_code + "-" + client.geo.region;
  }
}

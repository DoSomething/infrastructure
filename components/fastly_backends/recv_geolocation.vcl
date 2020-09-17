# Fixes issue where using location variables does not work as expected with shielding
# https://docs.fastly.com/vcl/geolocation/#using-geographic-variables-with-shielding
set client.geo.ip_override = req.http.Fastly-Client-IP;
# Return state code (in the US) on responses so that
# we can make use of this in client-side code.
set resp.http.X-Fastly-State-Code = client.geo.region;

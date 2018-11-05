# Ensure this value is only set within our VCL:
unset req.http.X-Synthetic-Response;

# If we're in between the start and end times, show the synthetic response:
# Times must be provided to Fastly in GMT (so the time in EST + 5 hours).
if (req.url.path ~ "(?i)^\/((us)\/?)?$"
    && time.is_after(now, std.time("Mon, 05 Nov 2018 00:00:00 GMT", std.integer2time(-1)))
    && time.is_after(std.time("Mon, 05 Nov 2018 23:03:00 GMT", std.integer2time(-1)), now)
) {
  set req.http.X-Synthetic-Response = "true";
}

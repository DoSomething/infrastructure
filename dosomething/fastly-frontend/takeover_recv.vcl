# Ensure this value is only set within our VCL:
unset req.http.X-Timed-Synthetic-Response;

# If we're on the US homepage at the right time, show the takeover:
if (req.url.path ~ "(?i)^\/((us)\/?)?$" &&
    # Fastly only deals with times in GMT (so we parse our time in EST and add 5 hours).
    time.is_after(now, time.add(std.time(var.takeover_start, std.integer2time(-1)), 5h)) &&
    time.is_after(time.add(std.time(var.takeover_end, std.integer2time(-1)), 5h), now)
) {
  set req.http.X-Timed-Synthetic-Response = "true";
}

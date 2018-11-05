declare local var.start_time TIME;
declare local var.end_time TIME;

# Here, we'll set the times for the takeover in EST (24 hour time):
set var.start_time = std.time("2018-11-05 00:00:00", std.integer2time(-1));
set var.end_time = std.time("2018-11-05 17:17:00", std.integer2time(-1));

# Ensure this value is only set within our VCL:
unset req.http.X-Synthetic-Response;

# If we're in between the start and end times, show the synthetic response:
# Times must be provided to Fastly in GMT (so the time in EST + 5 hours).
if (req.url.path ~ "(?i)^\/((us)\/?)?$"
    && time.is_after(now, time.add(var.start_time, 5h))
    && time.is_after(time.add(var.end_time, 5h), now)
) {
  set req.http.X-Synthetic-Response = "true";
}

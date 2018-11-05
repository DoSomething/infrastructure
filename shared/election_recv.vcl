declare local var.start_time TIME;
declare local var.end_time TIME;

# Times must be provided to Fastly in GMT (so the time in EST + 5 hours).
set var.start_time = std.time("Mon, 05 Nov 2018 00:00:00 GMT", std.integer2time(-1));
set var.end_time = std.time("Mon, 05 Nov 2018 09:35:00 GMT", std.integer2time(-1));

# TODO: Ensure this value is only set within our VCL:
# unset req.http.X-Synthetic-Response;

# If we're in between the start and end times, show the synthetic response:
if (req.url.path ~ "(?i)^\/((us)\/?)?$"
  && time.is_after(now, var.start_time)
  && time.is_after(var.end_time, now)
) {
  set req.http.X-Synthetic-Response = "true";
}

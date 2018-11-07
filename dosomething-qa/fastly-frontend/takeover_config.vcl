declare local var.takeover_start STRING;
declare local var.takeover_end STRING;

# This determines when a timed takeover is applied for this
# environment (see `shared/takeover_recv.vcl`). Times must
# be provided in 24-hour EST time.
set var.takeover_start = "2018-11-07 00:00:00";
set var.takeover_end = "2018-11-07 14:30:00";

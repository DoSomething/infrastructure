# Catch any */project/* page requests.
if (req.url ~ "(?i)^\/((us|mx|br)\/)?project")
  error 779 "Not Found";
}
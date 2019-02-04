# Catch any */project/* page requests.
if (req.url ~ "(?i)^\/((us|mx|br)\/)?project(s)?\/") {
  error 779 "Not Found";
}
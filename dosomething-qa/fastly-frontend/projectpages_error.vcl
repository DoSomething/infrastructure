if (obj.status == 779) {
  # Redirect any requests to */project/* and send them to the homepage.
  if (req.url ~ "(?i)^\/((us|mx|br)\/)?project") {
    set obj.http.Location = "/us"
    set obj.status = 404;
    return (deliver);
  }
}
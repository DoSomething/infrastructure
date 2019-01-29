if (obj.status == 779) {
  # Redirect any requests to */project/* and send them to the homepage.
  set obj.http.Location = "/us";
  set obj.status = 302;
  return (deliver);
}
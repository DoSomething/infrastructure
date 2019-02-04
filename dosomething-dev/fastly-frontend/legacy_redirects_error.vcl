if (obj.status == 800) {
  # Redirect requests to the specified path.
  set obj.http.Location = obj.response;
  set obj.status = 301;
  return (deliver);
}

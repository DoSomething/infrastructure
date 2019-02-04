if (obj.status == 800) {
  # Redirect requests to the homepage.
  set obj.http.Location = "/us";
  set obj.status = 301;
  return (deliver);
}

if (obj.status == 810) {
  set obj.http.Location = "/us/about/our-press";
  set obj.status = 301;
  return (deliver);
}

if (obj.status == 811) {
  set obj.http.Location = "/us/about/our-people";
  set obj.status = 301;
  return (deliver);
}

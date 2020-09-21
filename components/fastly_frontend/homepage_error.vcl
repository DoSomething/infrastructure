if (obj.status == 778) {
  # Capture any ? or # query string appended to the URL in the regex,
  # so we can retain that portion when rewriting the home page URL.
  #
  # This is in two if {} blocks because referring to re.group.1 when
  # it's empty results in "(null)" being appended to the URL, e.g.,
  #
  # /us(null)
  #
  # ...which is annoying. There's probably a NULL test, which would
  # let us simplify this.
  if (req.url ~ "^/([\?#].+)$") {
    set obj.http.Location = "/us" + re.group.1;
    set obj.status = 301;
    return(deliver);
  }
  if (req.url ~ "^/$") {
    set obj.http.Location = "/us";
    set obj.status = 301;
    return(deliver);
  }
}

// Handle a redirect to our static GDPR page, hosted by GitHub.
if (obj.status == 811) {
  set obj.status = 302;
  set obj.http.Location = "https://sorry.dosomething.org";
  set obj.response = "Found";
  return (deliver);
}

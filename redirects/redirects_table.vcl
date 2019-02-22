# This is where we define domain redirects! (See the "Trigger Redirect" and "Handle
# Redirect" snippets). To redirect a new domain, add the *origin* hostname
# on the left (where you're redirecting from), and the new URL (with protocol)
# on the right!
#
# Pro-tip: To ignore paths on a redirect (e.g. www.old.com/path to new.com/),
# end the "destination" URL with a hash! When redirected, the original path
# will be ignored by the destination web server! :)
#
table redirects {
  # Aurora:
  "aurora.dosomething.org": "https://admin.dosomething.org",
  "aurora-thor.dosomething.org": "https://admin-qa.dosomething.org",
  "aurora-qa.dosomething.org": "https://admin-dev.dosomething.org",
  "redirect.dosomething.org": "https://admin.dosomething.org",

  # Ashes:
  "thor.dosomething.org": "https://qa.dosomething.org",

  # International Affiliates:
  "uk.dosomething.org": "https://www.dosomething.org",
  "canada.dosomething.org": "https://www.dosomething.org",

  # Data:
  "data.dosomething.org": "https://dsdata.looker.com",

  # Northstar:
  "northstar.dosomething.org": "https://identity.dosomething.org",
  "northstar-thor.dosomething.org": "https://identity-qa.dosomething.org",
  "northstar-qa.dosomething.org": "https://identity-dev.dosomething.org",
  "profile.dosomething.org": "https://identity.dosomething.org",

  # Phoenix:
  "phoenix-preview.dosomething.org": "https://www-preview.dosomething.org",
  "www-dev.dosomething.org": "https://dev.dosomething.org",

  # Rogue:
  "rogue.dosomething.org": "https://activity.dosomething.org",
  "rogue-thor.dosomething.org": "https://activity-qa.dosomething.org",
  "rogue-qa.dosomething.org": "https://activity-dev.dosomething.org",
  
  # etc:
  "api.dosomething.org": "https://graphql.dosomething.org",
  "beta.dosomething.org": "https://www.dosomething.org",
  "files.dosomething.org": "https://www.dosomething.org",
  "m.dosomething.org": "https://www.dosomething.org",
  "www.teensforjeans.com": "https://www.dosomething.org/us/campaigns/teens-jeans",
  "www.dosomethingtote.org": "https://www.dosomething.org",
  "www.fourleggedfinishers.com": "https://www.dosomething.org/us/campaigns/four-legged-finishers#",
  "www.fourleggedfinishers.org": "https://www.dosomething.org/us/campaigns/four-legged-finishers#",
  "www.catsgonegood.com": "https://www.celebsgonegood.com",
}

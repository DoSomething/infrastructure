# Paths on `vote.dosomething.org` can be redirected here. You can optionally
# forward along a given `?r=...` query string by placing `[r]` into the
# destination URL.
table redirects {
  # example redirect. format: path -> target URL
  "/direct": "https://register.rockthevote.com/registrants/new?partner=37187&source=[r]",

  # partner/ad direct redirects <https://goo.gl/LKPofK>:
  # "/katiecouric": "https://register.rockthevote.com/registrants/new?partner=37187&source=campaignID:8017,campaignRunID:8022,source:influencer,source_details:katie_couric",
  # "/g/1": "https://register.rockthevote.com/registrants/new?partner=37187&source=ads",
  # "/g/2": "https://register.rockthevote.com/registrants/new?partner=37187&source=ads",
  # "/f/1": "https://register.rockthevote.com/registrants/new?partner=37187",
  # "/s/1": "https://register.rockthevote.com/registrants/new?partner=37187",
  # "/nationalschoolwalkout": "https://register.rockthevote.com/registrants/new?partner=37187&source=campaignID:8017,campaignRunID:8022,source:partner,source_details:NSW",
  # "/dmv": "https://register.rockthevote.com/registrants/new?partner=37187&source=campaignID:8017,campaignRunID:8022,source:partner,source_details:dmv_email",
  # "/johnlegend": "https://register.rockthevote.com/registrants/new?partner=37187&source=campaignID:8017,campaignRunID:8022,source:influencer,source_details:john_legend",
  # "/ehjovan": "https://register.rockthevote.com/registrants/new?partner=37187&source=campaignID:8017,campaignRunID:8022,source:influencer,source_details:jovan",
}

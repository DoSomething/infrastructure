# Redirect */actnow/* page requests.
if (req.url ~ "(?i)^\/((us|mx|br)\/)?actnow\/") { error 800 "/us"; }

# Redirect */programs/* page requests.
if (req.url ~ "(?i)^\/((us|mx|br)\/)?programs\/") { error 800 "/us"; }
  
# Redirect */project/* page requests.
if (req.url ~ "(?i)^\/((us|mx|br)\/)?project(s)?\/") { error 800 "/us"; }

# Redirect */about/press/* page requests.
if (req.url ~ "(?i)^\/((us|mx|br)\/)?about\/press\/") { error 800 "/us/about/our-press"; }

# Redirect */about/team/* page requests.
if (req.url ~ "(?i)^\/((us|mx|br)\/)?about\/team\/") { error 800 "/us/about/our-people"; }

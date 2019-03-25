# Redirect all MX and BR requests to the US site.
if (req.url ~ "(?i)^\/(mx|br)") { error 800 "/us"; }

# Redirect */actnow/* page requests.
if (req.url ~ "(?i)^\/(us\/)?actnow\/") { error 800 "/us"; }

# Redirect */programs/* page requests.
if (req.url ~ "(?i)^\/(us\/)?programs\/") { error 800 "/us"; }

# Redirect */project/* page requests.
if (req.url ~ "(?i)^\/(us\/)?project(s)?\/") { error 800 "/us"; }

# Redirect */about/press/* page requests.
if (req.url ~ "(?i)^\/(us\/)?about\/press\/") { error 800 "/us/about/our-press"; }

# Redirect */about/team/* page requests.
if (req.url ~ "(?i)^\/(us\/)?about\/team\/") { error 800 "/us/about/our-people"; }

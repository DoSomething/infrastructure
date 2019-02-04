# Redirect */actnow/* page requests.
if (req.url ~ "(?i)^\/((us|mx|br)\/)?actnow\/") { error 800 "Not Found"; }

# Redirect */programs/* page requests.
if (req.url ~ "(?i)^\/((us|mx|br)\/)?programs\/") { error 800 "Not Found"; }
  
# Redirect */project/* page requests.
if (req.url ~ "(?i)^\/((us|mx|br)\/)?project(s)?\/") { error 800 "Not Found"; }

# Redirect */about/press/* page requests.
if (req.url ~ "(?i)^\/((us|mx|br)\/)?about\/press\/") { error 810 "Not Found"; }

# Redirect */about/team/* page requests.
if (req.url ~ "(?i)^\/((us|mx|br)\/)?about\/team\/") { error 811 "Not Found"; }

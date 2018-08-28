# We store secrets in here to keep them safely out of
# version control. Check Lastpass for the 'Terraform
# secrets' shared note, under Shared-DevOps!

# AWS (read/write state & read-only resources):
# set with 'aws configure --profile terraform'

# Fastly:
fastly_api_key=

# Heroku:
heroku_email=
heroku_api_key=

# Papertrail:
papertrail_prod_destination="logsN.papertrailapp.com:NNNNN"
papertrail_qa_destination="logsN.papertrailapp.com:NNNNN"

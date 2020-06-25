{
    "Version": "2012-10-17",
    "Principal": {
        "AWS": "${fivetran_account_id}"
    },
    "Condition" : {
        "StringEquals": {
            "sts:ExternalId": "${external_id}" 
        }
    },
    "Effect": "Allow",
    "Sid": ""
  }
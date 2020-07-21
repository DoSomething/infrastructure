{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "PapertrailLogArchive",
        "Effect": "Allow",
        "Principal": {
          "AWS": [
            "arn:aws:iam::719734659904:root"
          ]
        },
        "Action": [
          "s3:DeleteObject",
          "s3:PutObject"
        ],
        "Resource": [
          "${bucket_arn}/*"
        ]
      }
    ]
  }
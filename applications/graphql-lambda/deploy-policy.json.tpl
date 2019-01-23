{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "CreateFunctionPermissions",
            "Effect": "Allow",
            "Action": [
                "lambda:UpdateFunctionCode"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": ["s3:ListBucket"],
            "Resource": ["${deploy_bucket_arn}"]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject"
            ],
            "Resource": ["${deploy_bucket_arn}/*"]
        }
    ]
}

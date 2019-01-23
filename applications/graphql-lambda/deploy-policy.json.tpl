{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ListExistingRolesAndPolicies",
            "Effect": "Allow",
            "Action": [
                "iam:ListRolePolicies",
                "iam:ListRoles"
            ],
            "Resource": "*"
        },
        {
            "Sid": "CreateFunctionPermissions",
            "Effect": "Allow",
            "Action": [
                "lambda:CreateFunction"
            ],
            "Resource": "*"
        },
        {
            "Sid": "PermissionToPassAnyRole",
            "Effect": "Allow",
            "Action": [
                "iam:PassRole"
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

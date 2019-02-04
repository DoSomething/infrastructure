{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParametersByPath",
                "ssm:GetParameters",
                "ssm:GetParameter"
            ],
            "Resource": "arn:aws:ssm:us-east-1:${account_id}:parameter/circleci/*"
        },
        {
           "Effect":"Allow",
           "Action":[
              "kms:Decrypt"
           ],
           "Resource":[
              "${kms_arn}"
           ]
        }
    ]
}

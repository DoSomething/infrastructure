{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "SpecificTable",
            "Resource": "arn:aws:dynamodb:*:*:table/${dynamodb_prefix}-*",
            "Effect": "Allow",
            "Action": [
                "dynamodb:CreateTable",
                "dynamodb:UpdateTable",
                "dynamodb:DescribeTable",
                "dynamodb:DescribeTimeToLive",


                "dynamodb:DeleteItem",
                "dynamodb:GetItem",
                "dynamodb:BatchGetItem",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
                "dynamodb:BatchWriteItem",
                "dynamodb:TransactGetItems",
                "dynamodb:TransactWriteItems",

                "dynamodb:Query",
                "dynamodb:Scan"
            ]
        }
    ]
}

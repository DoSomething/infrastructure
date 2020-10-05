{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "s3:ListBucket",
              "s3:GetBucketLocation"
          ],
          "Resource": [
              "arn:aws:s3:::*"
          ]
      },
      {
          "Effect": "Allow",
          "Action": [
              "s3:PutObject*",
              "s3:GetObject*",
              "s3:DeleteObject*"
          ],
          "Resource": [
              "arn:aws:s3:::dosomething-archive",
              "arn:aws:s3:::dosomething-archive/*"
          ]
      }
  ]
}

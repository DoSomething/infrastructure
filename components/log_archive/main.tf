resource "aws_s3_bucket" "archive" {
  bucket = var.name
  acl    = "private"

  tags = {
    Application = "papertrail"
    Environment = "all"
    Stack       = "all"
  }
}

resource "aws_s3_bucket_policy" "papertrail_access_policy" {
  bucket = aws_s3_bucket.archive.id
  policy = templatefile("${path.module}/policy.json.tpl", { bucket_arn = aws_s3_bucket.archive.arn })
}

resource "aws_s3_bucket_public_access_block" "private_policy" {
  bucket = aws_s3_bucket.archive.id

  # We don't want to risk a bug causing individual
  # log files to be marked with "public" ACLs.
  block_public_acls  = true
  ignore_public_acls = true

  # We need a "public" policy to grant Papertrail
  # write access to this bucket! See: policy.json.tpl.
  block_public_policy = false
}

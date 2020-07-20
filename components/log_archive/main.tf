variable "name" {
  description = "The name for the archive bucket (e.g. dosomething-papertrail)."
}

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

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
}
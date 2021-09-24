output "id" {
  value = aws_s3_bucket.bucket.id
}

output "region" {
  value = aws_s3_bucket.bucket.region
}

output "bucket" {
  value = aws_s3_bucket.bucket
}

output "config_vars" {
  value = {
    AWS_S3_BUCKET     = aws_s3_bucket.bucket.id
    AWS_S3_REGION     = aws_s3_bucket.bucket.region
    FILESYSTEM_DRIVER = "s3"

    # @TODO: Remove these old vars once safe to do so!
    STORAGE_DRIVER = "s3"
    S3_BUCKET      = aws_s3_bucket.bucket.id
    S3_REGION      = aws_s3_bucket.bucket.region
  }
}

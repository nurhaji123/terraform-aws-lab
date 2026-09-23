# Explicitly block all public access on the application buckets.
resource "aws_s3_bucket_public_access_block" "app_data" {
  count = length(aws_s3_bucket.app_data)

  bucket = aws_s3_bucket.app_data[count.index].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

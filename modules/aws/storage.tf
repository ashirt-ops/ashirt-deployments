resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "ashirt_storage" {
  bucket        = "ashirt-storage-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = {
    Name = "${local.name}-storage"
  }
}

# Server-side encryption with S3-managed keys (SSE-S3 / AES256). No
# customer-managed KMS key is involved.
resource "aws_s3_bucket_server_side_encryption_configuration" "ashirt_storage" {
  bucket = aws_s3_bucket.ashirt_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "ashirt_storage" {
  bucket = aws_s3_bucket.ashirt_storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "ashirt_storage" {
  bucket = aws_s3_bucket.ashirt_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

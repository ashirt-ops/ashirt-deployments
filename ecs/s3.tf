# Environment config and data buckets

resource "aws_s3_bucket" "env" {
  bucket = var.appenv
  tags = {
    Name = "${var.appenv}"
  }
}

resource "aws_s3_bucket_acl" "env_acl" {
  bucket = aws_s3_bucket.env.id
  acl    = "private"
}

resource "aws_s3_bucket" "data" {
  bucket        = var.appdata
  force_destroy = true
  tags = {
    Name = "${var.appdata}"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "env" {
  # If KMS enabled, use the key. Otherwise do not apply SSE
  count  = var.kms ? 1 : 0
  bucket = aws_s3_bucket.data.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms ? aws_kms_key.ashirt.0.arn : ""
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  count  = var.kms ? 1 : 0
  bucket = aws_s3_bucket.data.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms ? aws_kms_key.ashirt.0.arn : ""
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_acl" "data_acl" {
  bucket = aws_s3_bucket.data.id
  acl    = "private"
}

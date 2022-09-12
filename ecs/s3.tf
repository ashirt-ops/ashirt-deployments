# Environment config and data buckets

resource "aws_s3_bucket" "env" {
  bucket = var.envbucket
  acl    = "private"
  tags = {
    Name = "${var.app_name}-env"
  }
  # If KMS enabled, use the key. Otherwise do not apply SSE
  dynamic "server_side_encryption_configuration" {
    for_each = var.kms ? [1] : []
    content {
      rule {
        apply_server_side_encryption_by_default {
          kms_master_key_id = var.kms ? aws_kms_key.ashirt.0.arn : ""
          sse_algorithm     = "aws:kms"
        }
      }
    }
  }
}

resource "aws_s3_bucket" "data" {
  bucket        = var.appdata
  acl           = "private"
  force_destroy = true
  tags = {
    Name = "${var.app_name}-data"
  }
  dynamic "server_side_encryption_configuration" {
    for_each = var.kms ? [1] : []
    content {
      rule {
        apply_server_side_encryption_by_default {
          kms_master_key_id = var.kms ? aws_kms_key.ashirt.0.arn : ""
          sse_algorithm     = "aws:kms"
        }
      }
    }
  }
}

# Environment files

resource "aws_s3_bucket_object" "webenv" {
  bucket = aws_s3_bucket.env.id
  key    = "web/.env"
  source = ".env.web"
  etag   = filemd5(".env.web")
}

resource "aws_s3_bucket_object" "dbenv" {
  bucket  = aws_s3_bucket.env.id
  key     = "db/.env"
  content = "DB_URI=ashirt:${random_password.db_password.result}@tcp(${aws_rds_cluster.ashirt.endpoint}:3306)/ashirt"
}

resource "random_password" "csrf_key" {
  length  = 48
  special = true
}

resource "random_password" "session_key" {
  length  = 48
  special = false
}

resource "aws_s3_bucket_object" "appenv" {
  bucket  = aws_s3_bucket.env.id
  key     = "app/.env"
  content = <<EOT
APP_PORT=${var.app_port}
STORE_TYPE=s3
STORE_BUCKET=${var.appdata}
STORE_REGION=${var.region}
APP_IMGSTORE_REGION=${var.region}
APP_IMGSTORE_BUCKET_NAME=${var.appdata}
APP_CSRF_AUTH_KEY=${random_password.csrf_key.result}
APP_SESSION_STORE_KEY=${random_password.session_key.result}
APP_SUCCESS_REDIRECT_URL=https://${aws_route53_record.frontend.name}
APP_BACKEND_URL=https://${aws_route53_record.frontend.name}
APP_FRONTEND_INDEX_URL=https://${aws_route53_record.frontend.name}
AUTH_WEBAUTHN_RP_ORIGIN=https://${aws_route53_record.frontend.name}
AUTH_WEBAUTHN_TYPE=webauthn
AUTH_WEBAUTHN_NAME=webauthn
AUTH_WEBAUTHN_DISPLAY_NAME=webauthn
EOT
}

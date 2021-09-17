# Environment config and data buckets

resource "aws_s3_bucket" "env" {
  bucket = var.envbucket
  acl    = "private"
  tags = {
    Name = "${var.app_name}-env"
  }
}

resource "aws_s3_bucket" "data" {
  bucket        = var.appdata
  acl           = "private"
  force_destroy = true
  tags = {
    Name = "${var.app_name}-data"
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
  content = "DB_URI=ashirt:${var.db_password}@tcp(${aws_rds_cluster.ashirt.endpoint}:3306)/ashirt"
}

resource "aws_s3_bucket_object" "appenv" {
  bucket  = aws_s3_bucket.env.id
  key     = "app/.env"
  content = "APP_PORT=${var.app_port}\nAPP_IMGSTORE_BUCKET_NAME=${var.appdata}\nAPP_IMGSTORE_REGION=${var.region}"
}

# Init Secrets and environment files
resource "random_password" "csrf_key" {
  length  = 48
  special = true
}

resource "random_password" "session_key" {
  length  = 48
  special = false
}

resource "aws_s3_object" "webenv" {
  bucket  = aws_s3_bucket.env.id
  key     = "web/.env"
  content = <<EOT
# Add "google" to the two lists below if you want to set up google oidc
AUTH_SERVICES=ashirt,webauthn
AUTH_SERVICES_ALLOW_REGISTRATION=ashirt,webauthn

# Add client id and secret to enable google oidc
AUTH_GOOGLE_TYPE=oidc
AUTH_GOOGLE_NAME=google
AUTH_GOOGLE_FRIENDLY_NAME=Google OIDC
AUTH_GOOGLE_CLIENT_ID=
AUTH_GOOGLE_CLIENT_SECRET=
AUTH_GOOGLE_SCOPES=email
AUTH_GOOGLE_PROVIDER_URL=https://accounts.google.com

APP_PORT=${var.app_port}
STORE_TYPE=s3
STORE_BUCKET=${var.appdata}
STORE_REGION=${var.region}
APP_IMGSTORE_REGION=${var.region}
APP_IMGSTORE_BUCKET_NAME=${var.appdata}
APP_CSRF_AUTH_KEY=${random_password.csrf_key.result}
APP_SESSION_STORE_KEY=${random_password.session_key.result}
APP_SUCCESS_REDIRECT_URL=https://${aws_route53_record.frontend.name}
APP_BACKEND_URL=https://${aws_route53_record.frontend.name}/web
APP_FRONTEND_INDEX_URL=https://${aws_route53_record.frontend.name}
AUTH_WEBAUTHN_RP_ORIGIN=https://${aws_route53_record.frontend.name}
AUTH_WEBAUTHN_TYPE=webauthn
AUTH_WEBAUTHN_NAME=webauthn
AUTH_WEBAUTHN_DISPLAY_NAME=webauthn
EMAIL_TYPE=smtp
EMAIL_HOST=email-smtp.${var.region}.amazonaws.com:587
EMAIL_FROM_ADDRESS=ashirt@${aws_route53_record.frontend.name}
EMAIL_USER_NAME=${aws_iam_access_key.ashirt_smtp_user.id}
EMAIL_PASSWORD=${aws_iam_access_key.ashirt_smtp_user.ses_smtp_password_v4}
EMAIL_SMTP_AUTH_TYPE=login
EOT
}

resource "aws_s3_object" "appenv" {
  bucket  = aws_s3_bucket.env.id
  key     = "app/.env"
  content = <<EOT
APP_PORT=${var.app_port}
STORE_TYPE=s3
STORE_BUCKET=${var.appenv}
STORE_REGION=${var.region}
EOT
}

resource "aws_s3_object" "dbenv" {
  bucket  = aws_s3_bucket.env.id
  key     = "db/.env"
  content = "DB_URI=ashirt:${random_password.db_password.result}@tcp(${aws_rds_cluster.ashirt.endpoint}:3306)/ashirt"
}

resource "aws_kms_key" "ashirt" {
  count       = var.kms ? 1 : 0
  description = "ashirt default key"
  #deletion_window_in_days = 10
  enable_key_rotation = true
  tags = {
    Name = "${var.app_name}-key"
  }
}

resource "aws_kms_alias" "ashirt" {
  count         = var.kms ? 1 : 0
  name          = "alias/ashirt"
  target_key_id = aws_kms_key.ashirt[count.index].key_id
}

# Create a Google Cloud KMS key ring
resource "google_kms_key_ring" "ashirt" {
  name     = "${var.app_name}-key-ring"
  location = "global"  # Replace with the appropriate location
}

# Create a Google Cloud KMS key
resource "google_kms_crypto_key" "ashirt" {
  name     = "${var.app_name}-crypto-key"
  key_ring = google_kms_key_ring.ashirt.self_link

  purpose = "ENCRYPT_DECRYPT"  # Adjust the purpose as needed

  rotation_period = "7776000s"  # Rotate every 90 days, adjust as needed

  version_template {
    algorithm       = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "HSM"  # Choose the appropriate protection level
  }
}

# Create a key alias for the KMS key
resource "google_kms_key_ring" "alias" {
  name     = "${var.app_name}-key-ring"  # Use the same key ring as above
  location = "global"
}

resource "google_kms_crypto_key" "alias" {
  name     = "${var.app_name}-alias"
  key_ring = google_kms_key_ring.alias.self_link

  purpose = "ENCRYPT_DECRYPT"  # Adjust the purpose as needed

  rotation_period = "7776000s"  # Rotate every 90 days, adjust as needed

  version_template {
    algorithm       = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "HSM"  # Choose the appropriate protection level
  }
}

# Create an alias for the KMS key
resource "google_kms_crypto_key_crypto_key_version" "alias" {
  key         = google_kms_crypto_key.alias.self_link
  version     = 1  # Use the appropriate version
  crypto_key  = google_kms_crypto_key.ashirt.self_link
}

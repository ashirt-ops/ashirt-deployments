resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "google_storage_bucket" "ashirt_storage" {
  name          = "ashirt-storage-${random_string.bucket_suffix.result}"
  location      = var.region
  force_destroy = true
}

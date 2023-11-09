# Environment config and data buckets

resource "google_storage_bucket" "env" {
  name = var.appenv
  location = "US"
  force_destroy = true
}

resource "google_storage_bucket" "data" {
  name = var.appdata
  location = "US"
  force_destroy = true
}

# TODO TN how is the backend saving to this?
resource "google_project_service" "storage" {
  // TODO does this need a project ID?
  service = "storage.googleapis.com"
}

resource "google_storage_bucket_iam_binding" "env" {
  bucket = google_storage_bucket.env.name
  role   = "roles/storage.admin"
  members = ["user:${google_project_service.storage.project_number}@cloudbuild.gserviceaccount.com"]
}

resource "google_storage_bucket_iam_binding" "data" {
  bucket = google_storage_bucket.data.name
  role   = "roles/storage.admin"
  members = ["user:${google_project_service.storage.project_number}@cloudbuild.gserviceaccount.com"]
}

resource "google_storage_bucket_iam_member" "env_owner" {
  bucket = google_storage_bucket.env.name
  role   = "roles/storage.objectAdmin"
  // TODO TN - add this user in as a variable somewhere?
  member = "user:your-email@example.com"
}

resource "google_storage_bucket_iam_member" "data_owner" {
  bucket = google_storage_bucket.data.name
  role   = "roles/storage.objectAdmin"
  // TODO TN update this as well
  member = "user:your-email@example.com"
}

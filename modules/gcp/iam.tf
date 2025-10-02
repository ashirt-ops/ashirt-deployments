resource "google_project_iam_member" "backend-storage-viewer" {
  project = var.project
  role    = "roles/storage.objectViewer"
  member  = google_service_account.backend.member
}

resource "google_project_iam_member" "backend-storage-creator" {
  project = var.project
  role    = "roles/storage.objectCreator"
  member  = google_service_account.backend.member
}

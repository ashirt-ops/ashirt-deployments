resource "google_project_iam_member" "backend-storage-user" {
  project = var.project
  role    = "roles/storage.objectUser"
  member  = google_service_account.backend.member
}

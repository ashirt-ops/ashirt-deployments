resource "google_project_iam_member" "backend-storage-user" {
  project = var.project
  role    = "roles/storage.objectUser"
  member  = google_service_account.backend.member
}

resource "google_project_iam_member" "ocr_worker_service_usage" {
  project = var.project
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = google_service_account.ocr_worker.member
}

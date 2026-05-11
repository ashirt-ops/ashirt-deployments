resource "google_project_iam_member" "ashirt-server-storage-user" {
  project = var.project
  role    = "roles/storage.objectUser"
  member  = google_service_account.ashirt_server.member
}

resource "google_project_iam_member" "ocr_worker_service_usage" {
  project = var.project
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = google_service_account.ocr_worker.member
}

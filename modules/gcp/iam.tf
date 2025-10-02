resource "google_project_iam_member" "backend-storage-get" {
  project = var.project
  role    = "roles/storage.objects.get"
  member  = google_service_account.backend
}

resource "google_project_iam_member" "backend-storage-list" {
  project = var.project
  role    = "roles/storage.objects.list"
  member  = google_service_account.backend
}

resource "google_project_iam_member" "backend-storage-create" {
  project = var.project
  role    = "roles/storage.objects.create"
  member  = google_service_account.backend
}

resource "google_project_iam_member" "backend-storage-delete" {
  project = var.project
  role    = "roles/storage.objects.delete"
  member  = google_service_account.backend
}

resource "google_project_service" "secretmanager" {
  project            = var.project
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "vpcaccess-api" {
  project            = var.project
  service            = "vpcaccess.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "servicenetworking" {
  project            = var.project
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "run" {
  project            = var.project
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "compute" {
  project            = var.project
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "vision" {
  project            = var.project
  service            = "vision.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iap" {
  project            = var.project
  service            = "iap.googleapis.com"
  disable_on_destroy = false
}

# google_project_service returns success as soon as the enable RPC is accepted,
# but the underlying APIs can take up to ~60s to become fully usable. Without
# this pad, downstream resources race ahead and fail with "API not enabled" or
# variants thereof.
resource "time_sleep" "wait_for_services" {
  depends_on = [
    google_project_service.secretmanager,
    google_project_service.vpcaccess-api,
    google_project_service.servicenetworking,
    google_project_service.run,
    google_project_service.compute,
    google_project_service.vision,
    google_project_service.iap,
  ]

  create_duration = "60s"
}

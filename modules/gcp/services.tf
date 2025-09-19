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

#resource "google_project_service" "domains" {
#  project            = var.project
#  service            = "domains.googleapis.com"
#  disable_on_destroy = false
#}

#resource "google_project_service" "domains" {
#  project            = var.project
#  service            = "dns.googleapis.com"
#  disable_on_destroy = false
#}

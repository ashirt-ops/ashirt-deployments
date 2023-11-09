# Set the Google Cloud provider
provider "google" {
  project    = locals.project_id
  region     = var.region
}

locals {
  project_id = data.google_project.current.project_id
}
# Data source to get the list of available regions in GCP
data "google_compute_regions" "available_regions" {}

# Data source to get the current authenticated user's identity
data "google_client_config" "current" {}

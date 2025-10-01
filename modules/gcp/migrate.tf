resource "google_cloud_run_v2_job" "init_api" {
  deletion_protection = false
  project             = var.project
  name                = "ashirt-migrate-${var.environment}"
  location            = var.region
  template {
    template {
      service_account = google_service_account.backend.email
      containers {
        image = "docker.io/ashirt/init:${var.tag}"

        env {
          name = "DB_URI"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.ashirt_dsn.secret_id
              version = "latest"
            }
          }
        }
      }

      vpc_access {
        network_interfaces {
          network    = google_compute_network.vpc_network.id
          subnetwork = google_compute_subnetwork.subnet[0].name
          tags       = []
        }

        egress = "ALL_TRAFFIC"
      }
    }
  }
}

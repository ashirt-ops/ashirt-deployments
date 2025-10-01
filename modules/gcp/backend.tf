resource "google_service_account" "backend" {
  project      = var.project
  account_id   = "backend-service-${var.environment}"
  display_name = "backend"
}

resource "random_password" "session_key" {
  length  = 48
  special = false
}

resource "google_cloud_run_v2_service" "backend" {
  project  = var.project
  name     = "backend-${var.environment}"
  location = var.region
  # TODO: change
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    service_account = google_service_account.backend.email

    containers {
      image = "docker.io/ashirt/web:${var.tag}"

      env {
        name  = "APP_IMGSTORE_BUCKET_NAME"
        value = google_storage_bucket.ashirt_storage.name
      }

      env {
        name  = "APP_IMGSTORE_REGION"
        value = var.region
      }

      env {
        name  = "STORE_TYPE"
        value = "gcp"
      }

      env {
        name  = "APP_PORT"
        value = "8000"
      }

      env {
        name  = "APP_SESSION_STORE_KEY"
        value = random_password.session_key.result
      }

      env {
        name = "DB_URI"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.ashirt_dsn.secret_id
            version = "latest"
          }
        }
      }

      dynamic "env" {
        for_each = var.backend_env

        content {
          name  = env.key
          value = env.value
        }
      }


      resources {
        startup_cpu_boost = true
        cpu_idle          = true
      }

      ports {
        container_port = 8000
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

#resource "google_compute_firewall" "backend_firewall" {
#  project = var.project
#  name    = "ashirt-${var.environment}-backend-firewall"
#  network = google_compute_network.vpc_network.id
#
#  allow {
#    protocol = "tcp"
#    ports    = [8000]
#  }
#
#  source_ranges = ["0.0.0.0/0"]
#  target_tags   = ["backend"]
#}

#resource "google_compute_region_network_endpoint_group" "backend" {
#  project               = var.project
#  name                  = "backend"
#  network_endpoint_type = "SERVERLESS"
#  region                = var.region
#
#  cloud_run {
#    service = google_cloud_run_v2_service.backend.name
#  }
#}

#module "lb-http-backend" {
#  source  = "terraform-google-modules/lb-http/google//modules/serverless_negs"
#  version = "~> 13"
#  name    = "backend"
#  project = var.project
#  ssl     = false
#  #managed_ssl_certificate_domains = [""]
#  https_redirect = false
#
#  backends = {
#    default = {
#      description = null
#      groups = [
#        {
#          group = google_compute_region_network_endpoint_group.backend.id
#        }
#      ]
#
#      enable_cdn = false
#
#      iap_config = {
#        enable = false
#      }
#      log_config = {
#        enable = false
#      }
#    }
#  }
#}

resource "google_cloud_run_service_iam_member" "backend_public_access" {
  location = google_cloud_run_v2_service.backend.location
  project  = google_cloud_run_v2_service.backend.project
  service  = google_cloud_run_v2_service.backend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

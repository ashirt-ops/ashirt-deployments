resource "google_service_account" "frontend" {
  project      = var.project
  account_id   = "ashirt-frontend-${var.environment}"
  display_name = "ashirt frontend ${var.environment}"
}

resource "google_cloud_run_v2_service" "frontend" {
  project  = var.project
  name     = "frontend-${var.environment}"
  location = var.region
  # TODO: change
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    service_account = google_service_account.frontend.email

    containers {
      image = "docker.io/ashirt/frontend:${var.tag}"

      env {
        name  = "NGINX_PORT"
        value = "8080"
      }

      env {
        name  = "WEB_URL"
        value = google_cloud_run_v2_service.backend.uri
      }

      resources {
        startup_cpu_boost = true
        cpu_idle          = true
      }

      ports {
        container_port = 8080
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

#resource "google_compute_firewall" "frontend_firewall" {
#  project = var.project
#  name    = "ashirt-${var.environment}-frontend-firewall"
#  network = google_compute_network.vpc_network.id
#
#  allow {
#    protocol = "tcp"
#    ports    = ["8080"]
#  }
#
#  source_ranges = ["0.0.0.0/0"]
#  target_tags   = ["frontend"]
#}

#module "lb-http-frontend" {
#  source  = "terraform-google-modules/lb-http/google//modules/serverless_negs"
#  version = "~> 13"
#  name    = "frontend"
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
#          group = google_compute_region_network_endpoint_group.frontend.id
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

#resource "google_compute_region_network_endpoint_group" "frontend" {
#  project               = var.project
#  provider              = google
#  name                  = "frontend"
#  network_endpoint_type = "SERVERLESS"
#  region                = var.region
#
#  cloud_run {
#    service = google_cloud_run_v2_service.frontend.name
#  }
#}

resource "google_cloud_run_service_iam_member" "frontend_public_access" {
  location = google_cloud_run_v2_service.frontend.location
  project  = google_cloud_run_v2_service.frontend.project
  service  = google_cloud_run_v2_service.frontend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

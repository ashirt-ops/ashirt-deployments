resource "google_service_account" "ashirt_server" {
  project      = var.project
  account_id   = "ashirt-server-${var.environment}"
  display_name = "ashirt-server ${var.environment}"
}

resource "random_password" "session_key" {
  length  = 48
  special = false
}

resource "google_cloud_run_v2_service" "ashirt_server" {
  project  = var.project
  name     = "ashirt-server-${var.environment}"
  location = var.region
  # TODO: change
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    service_account = google_service_account.ashirt_server.email

    containers {
      image = "docker.io/ashirt/ashirt-server:${var.tag}"

      env {
        name  = "STORE_TYPE"
        value = "gcp"
      }

      env {
        name  = "STORE_BUCKET"
        value = google_storage_bucket.ashirt_storage.name
      }

      env {
        name  = "STORE_REGION"
        value = google_storage_bucket.ashirt_storage.location
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
        for_each = var.ashirt_server_env

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

  scaling {
    min_instance_count = var.min_ashirt_server_instances
  }

  depends_on = [google_secret_manager_secret_iam_binding.ashirt_server_sql_secret]
}

resource "google_cloud_run_service_iam_member" "ashirt_server_public_access" {
  location = google_cloud_run_v2_service.ashirt_server.location
  project  = google_cloud_run_v2_service.ashirt_server.project
  service  = google_cloud_run_v2_service.ashirt_server.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

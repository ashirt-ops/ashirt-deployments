resource "google_service_account" "ocr_worker" {
  project      = var.project
  account_id   = "ashirt-ocr-worker-${var.environment}"
  display_name = "ashirt ocr-worker ${var.environment}"
}

resource "google_secret_manager_secret" "ocr_worker_access_key" {
  project   = var.project
  secret_id = "ashirt-ocr-worker-access-key-${var.environment}"
  labels = {
    label = "ashirt-ocr-worker-access-key-${var.environment}"
  }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "ocr_worker_access_key" {
  secret      = google_secret_manager_secret.ocr_worker_access_key.id
  secret_data = var.ocr_worker_access_key
}

resource "google_secret_manager_secret" "ocr_worker_secret_key" {
  project   = var.project
  secret_id = "ashirt-ocr-worker-secret-key-${var.environment}"
  labels = {
    label = "ashirt-ocr-worker-secret-key-${var.environment}"
  }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "ocr_worker_secret_key" {
  secret      = google_secret_manager_secret.ocr_worker_secret_key.id
  secret_data = var.ocr_worker_secret_key
}

resource "google_secret_manager_secret_iam_binding" "ocr_worker_access_key" {
  project   = var.project
  secret_id = google_secret_manager_secret.ocr_worker_access_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  members = [
    "serviceAccount:${google_service_account.ocr_worker.email}",
  ]
}

resource "google_secret_manager_secret_iam_binding" "ocr_worker_secret_key" {
  project   = var.project
  secret_id = google_secret_manager_secret.ocr_worker_secret_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  members = [
    "serviceAccount:${google_service_account.ocr_worker.email}",
  ]
}

resource "google_cloud_run_v2_service" "ocr_worker" {
  project             = var.project
  name                = "ocr-worker-${var.environment}"
  location            = var.region
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    service_account = google_service_account.ocr_worker.email

    containers {
      image = "docker.io/ashirt/ocr-worker:${var.ocr_worker_tag}"

      env {
        name  = "API_BASE"
        value = google_cloud_run_v2_service.ashirt_server.uri
      }

      env {
        name = "ACCESS_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.ocr_worker_access_key.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "SECRET_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.ocr_worker_secret_key.secret_id
            version = "latest"
          }
        }
      }

      dynamic "env" {
        for_each = var.ocr_worker_env

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

  scaling {
    min_instance_count = var.min_ocr_worker_instances
  }

  depends_on = [
    google_secret_manager_secret_iam_binding.ocr_worker_access_key,
    google_secret_manager_secret_iam_binding.ocr_worker_secret_key,
  ]
}

resource "google_cloud_run_service_iam_member" "ocr_worker_ashirt_server_invoker" {
  location = google_cloud_run_v2_service.ocr_worker.location
  project  = google_cloud_run_v2_service.ocr_worker.project
  service  = google_cloud_run_v2_service.ocr_worker.name
  role     = "roles/run.invoker"
  member   = google_service_account.ashirt_server.member
}

resource "google_cloud_run_service_iam_member" "ocr_worker_public_access" {
  location = google_cloud_run_v2_service.ocr_worker.location
  project  = google_cloud_run_v2_service.ocr_worker.project
  service  = google_cloud_run_v2_service.ocr_worker.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

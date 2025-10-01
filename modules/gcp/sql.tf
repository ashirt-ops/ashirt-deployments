resource "random_password" "db_root_password" {
  length  = 24
  special = false
}

resource "random_password" "ashirt_db_password" {
  length  = 24
  special = false
}

resource "google_compute_global_address" "private_ip_address" {
  project       = var.project
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 20
  network       = google_compute_network.vpc_network.id
}

resource "google_service_networking_connection" "vpc_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_sql_database_instance" "ashirt" {
  project             = var.project
  name                = "ashirt-${var.environment}"
  database_version    = "MYSQL_8_0"
  region              = var.region
  root_password       = random_password.db_root_password.result
  deletion_protection = false

  settings {
    tier              = var.db_tier
    edition           = var.db_edition
    availability_type = var.db_availability_type
    # TODO: do we want this enabled?
    deletion_protection_enabled = false

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc_network.id

      authorized_networks {
        name  = "all"
        value = "0.0.0.0/0"
      }
    }

    backup_configuration {
      enabled            = true
      binary_log_enabled = true
    }
  }
}

resource "google_sql_database" "ashirt" {
  project  = var.project
  name     = "ashirt"
  instance = google_sql_database_instance.ashirt.name
}

resource "google_secret_manager_secret" "ashirt_dsn" {
  project   = var.project
  secret_id = "ashirt-dsn-${var.environment}"
  labels = {
    label = "ashirt-dsn-${var.environment}"
  }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "ashirt" {
  secret      = google_secret_manager_secret.ashirt_dsn.id
  secret_data = "ashirt:${random_password.ashirt_db_password.result}@tcp(${google_sql_database_instance.ashirt.ip_address.0.ip_address}:3306)/ashirt"
}

resource "google_secret_manager_secret_iam_binding" "backend_sql_secret" {
  project   = var.project
  secret_id = google_secret_manager_secret.ashirt_dsn.secret_id
  role      = "roles/secretmanager.secretAccessor"
  members = [
    //"serviceAccount:${var.project_id}-compute@developer.gserviceaccount.com",
    "serviceAccount:${google_service_account.backend.email}",
  ]
}

resource "google_sql_user" "ashirt" {
  project    = var.project
  name       = "ashirt"
  host       = "%"
  instance   = google_sql_database_instance.ashirt.name
  password   = random_password.ashirt_db_password.result
  depends_on = [google_sql_database_instance.ashirt]
}

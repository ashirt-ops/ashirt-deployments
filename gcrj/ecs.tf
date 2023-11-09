resource "random_password" "csrf_key" {
  length  = 48
  special = true
}

resource "random_password" "session_key" {
  length  = 48
  special = false
}

resource "google_cloud_run_v2_service" "ashirt-web" {
  name     = "${var.app_name}-web" #"ashirt-service"
  location = var.region
  # TODO TN figure this out
  ingress = "INGRESS_TRAFFIC_ALL"


  template {
    scaling {
      max_instance_count = var.web_count
      // TODO TN - I don't think we want min listed, but idk for sure
    }

    vpc_access{
      connector = google_vpc_access_connector.connector.id
      # TODO TN what should this be?
      egress = "ALL_TRAFFIC"
    }

    containers {
      # TODO TN - how to save image here?
      # TODO TN i dont thik porject ID is a var -= change this
      # image = "gcr.io/${var.project_id}/${google_cloud_run_service.ashirt.name}:${var.tag}"
      image = "gcr.io/${locals.project_id}/${var.app_name}-web:${var.tag}"

      ports {
        container_port = var.app_port
      }
      
      env {
        name = "AUTH_SERVICES"
        value = "ashirt,webauthn"
      }

      env {
        name = "AUTH_SERVICES_ALLOW_REGISTRATION"
        value = "ashirt,webauthn"
      }

      env {
        name = "AUTH_GOOGLE_TYPE"
        value = "oidc"
      }

      env {
        name = "AUTH_GOOGLE_NAME"
        value = "google"
      }

      env {
        name = "AUTH_GOOGLE_FRIENDLY_NAME"
        value = "Google OIDC"
      }

      env {
        name = "AUTH_GOOGLE_CLIENT_ID"
        value = ""
      }

      env {
        name = "AUTH_GOOGLE_CLIENT_SECRET"
        value = ""
      }

      env {
        name = "AUTH_GOOGLE_SCOPES"
        value = "email"
      }

      env {
        name = "AUTH_GOOGLE_PROVIDER_URL"
        value = "https://accounts.google.com"
      }

      env {
        name = "APP_PORT"
        value = "${var.app_port}"
      }

      env {
        name = "STORE_TYPE"
        value = "gcs"
      }

      env {
        name = "STORE_BUCKET"
        value = "${google_storage_bucket.data.name}"
      }

      env {
        name = "STORE_REGION"
        value = "${var.region}"
      }

      env {
        name = "APP_IMGSTORE_REGION"
        value = "${var.region}"
      }

      env {
        name = "APP_IMGSTORE_BUCKET_NAME"
        value = "${google_storage_bucket.data.name}"
      }

      env {
        name = "APP_CSRF_AUTH_KEY"
        value = "${random_password.csrf_key.result}"
      }

      env {
        name = "APP_SESSION_STORE_KEY"
        value = "${random_password.session_key.result}"
      }

      env {
        name = "APP_SUCCESS_REDIRECT_URL"
        value = "https://${google_dns_managed_zone.ashirt.name}"
      }

      env {
        name = "APP_BACKEND_URL"
        value = "https://${google_dns_managed_zone.ashirt.name}/web"
      }

      env {
        name = "APP_FRONTEND_INDEX_URL"
        value = "https://${google_dns_managed_zone.ashirt.name}"
      }

      env {
        name = "AUTH_WEBAUTHN_RP_ORIGIN"
        value = "https://${google_dns_managed_zone.ashirt.name}"
      }

      env {
        name = "AUTH_WEBAUTHN_TYPE"
        value = "webauthn"
      }

      env {
        name = "AUTH_WEBAUTHN_NAME"
        value = "webauthn"
      }

      env {
        name = "AUTH_WEBAUTHN_DISPLAY_NAME"
        value = "webauthn"
      }

      env {
        name = "EMAIL_TYPE"
        value = "smtp"
      }

      env {
        name = "EMAIL_HOST"
        # TODO TN - what should this be?
        value = "email-smtp.${var.region}.amazonaws.com:587"
      }

      env {
        name = "EMAIL_FROM_ADDRESS"
        value = "ashirt@${google_dns_managed_zone.ashirt.name}"
      }

      env {
        name = "EMAIL_USER_NAME"
        value = ""
      }

      env {
        name = "EMAIL_PASSWORD"
        value = ""
      }

      env {
        name = "EMAIL_SMTP_AUTH_TYPE"
        value = "login"
      }

      env {
        name = "DB_URI"
        value = "ashirt:${random_password.db_password.result}@tcp(${google_sql_database_instance.ashirt_db.private_ip_address}:3306)/ashirt"
      }
    }
  }

# TODO TN probably not needed, look into
  # Environment variables
  # template {
  #   metadata {
  #     annotations = {
  #       # TODO TN - what is this part?
  #       "run.googleapis.com/cloudsql-instances" = "your-project:your-region:your-cloud-sql-instance"
  #     }
  #   }
  # }

# TODO TN probably not needed, look into
  # traffic {
  #   percent         = 100
  # }
}

# Define the Google Cloud Run service
resource "google_cloud_run_v2_service" "ashirt-frontend" {
  name     = "${var.app_name}-frontend" 
  location = var.region
  ingress = "INGRESS_TRAFFIC_ALL"


  template {
    containers {
      image = "gcr.io/${locals.project_id}/${var.app_name}-frontend:${var.tag}"

      ports {
        container_port = var.app_port
      }

    # TODO TN - should I figure out which env vars I actually need for the frotend? I may not need any
      env {
        name = "AUTH_SERVICES"
        value = "ashirt,webauthn"
      }

      env {
        name = "AUTH_SERVICES_ALLOW_REGISTRATION"
        value = "ashirt,webauthn"
      }

      env {
        name = "AUTH_GOOGLE_TYPE"
        value = "oidc"
      }

      env {
        name = "AUTH_GOOGLE_NAME"
        value = "google"
      }

      env {
        name = "AUTH_GOOGLE_FRIENDLY_NAME"
        value = "Google OIDC"
      }

      env {
        name = "AUTH_GOOGLE_CLIENT_ID"
        value = ""
      }

      env {
        name = "AUTH_GOOGLE_CLIENT_SECRET"
        value = ""
      }

      env {
        name = "AUTH_GOOGLE_SCOPES"
        value = "email"
      }

      env {
        name = "AUTH_GOOGLE_PROVIDER_URL"
        value = "https://accounts.google.com"
      }

      env {
        name = "APP_PORT"
        value = "${var.app_port}"
      }

      env {
        name = "STORE_TYPE"
        value = "gcs"
      }

      env {
        name = "STORE_BUCKET"
        value = "${google_storage_bucket.data.name}"
      }

      env {
        name = "STORE_REGION"
        value = "${var.region}"
      }

      env {
        name = "APP_IMGSTORE_REGION"
        value = "${var.region}"
      }

      env {
        name = "APP_IMGSTORE_BUCKET_NAME"
        value = "${google_storage_bucket.data.name}"
      }

      env {
        name = "APP_CSRF_AUTH_KEY"
        value = "${random_password.csrf_key.result}"
      }

      env {
        name = "APP_SESSION_STORE_KEY"
        value = "${random_password.session_key.result}"
      }

      env {
        name = "APP_SUCCESS_REDIRECT_URL"
        value = "https://${google_dns_managed_zone.ashirt.name}"
      }

      env {
        name = "APP_BACKEND_URL"
        value = "https://${google_dns_managed_zone.ashirt.name}/web"
      }

      env {
        name = "APP_FRONTEND_INDEX_URL"
        value = "https://${google_dns_managed_zone.ashirt.name}"
      }

      env {
        name = "AUTH_WEBAUTHN_RP_ORIGIN"
        value = "https://${google_dns_managed_zone.ashirt.name}"
      }

      env {
        name = "AUTH_WEBAUTHN_TYPE"
        value = "webauthn"
      }

      env {
        name = "AUTH_WEBAUTHN_NAME"
        value = "webauthn"
      }

      env {
        name = "AUTH_WEBAUTHN_DISPLAY_NAME"
        value = "webauthn"
      }

      env {
        name = "EMAIL_TYPE"
        value = "smtp"
      }

      env {
        name = "EMAIL_HOST"
        # TODO TN - what should this be?
        value = "email-smtp.${var.region}.amazonaws.com:587"
      }

      env {
        name = "EMAIL_FROM_ADDRESS"
        value = "ashirt@${google_dns_managed_zone.ashirt.name}"
      }

      env {
        name = "EMAIL_USER_NAME"
        value = ""
      }

      env {
        name = "EMAIL_PASSWORD"
        value = ""
      }

      env {
        name = "EMAIL_SMTP_AUTH_TYPE"
        value = "login"
      }

      env {
        name = "DB_URI"
        value = "ashirt:${random_password.db_password.result}@tcp(${google_sql_database_instance.ashirt_db.private_ip_address}:3306)/ashirt"
      }
    }
  }

# TODO TN probably not needed, look into
  # traffic {
  #   percent         = 100
  #   latest_revision = true
  # }
  #   autogenerate_revision_name = true
}

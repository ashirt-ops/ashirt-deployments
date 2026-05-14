data "google_project" "this" {
  project_id = var.project
}

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
        value = google_cloud_run_v2_service.ashirt_server.uri
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
    min_instance_count = var.min_frontend_instances
  }
}

resource "google_compute_region_network_endpoint_group" "frontend" {
  project               = var.project
  name                  = "frontend-${var.environment}"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  cloud_run {
    service = google_cloud_run_v2_service.frontend.name
  }
}

locals {
  frontend_backend_base = {
    description = null
    groups = [
      {
        group = google_compute_region_network_endpoint_group.frontend.id
      }
    ]
    enable_cdn = false
    log_config = {
      enable = false
    }
  }

  frontend_backends = var.iap_enabled ? {
    default = merge(local.frontend_backend_base, {
      iap_config = { enable = true }
    })
    api = merge(local.frontend_backend_base, {
      iap_config = { enable = false }
    })
    } : {
    default = merge(local.frontend_backend_base, {
      iap_config = { enable = false }
    })
  }
}

module "lb-http-frontend" {
  source  = "terraform-google-modules/lb-http/google//modules/serverless_negs"
  version = "~> 14"
  name    = "frontend-${var.environment}"
  project = var.project

  ssl                             = true
  managed_ssl_certificate_domains = [var.frontend_domain]
  https_redirect                  = true

  create_url_map = !var.iap_enabled
  url_map        = var.iap_enabled ? google_compute_url_map.frontend[0].self_link : null

  backends = local.frontend_backends
}

resource "google_compute_url_map" "frontend" {
  count           = var.iap_enabled ? 1 : 0
  project         = var.project
  name            = "frontend-${var.environment}-url-map"
  default_service = module.lb-http-frontend.backend_services["default"].self_link

  host_rule {
    hosts        = [var.frontend_domain]
    path_matcher = "main"
  }

  path_matcher {
    name            = "main"
    default_service = module.lb-http-frontend.backend_services["default"].self_link

    path_rule {
      paths   = ["/api", "/api/*"]
      service = module.lb-http-frontend.backend_services["api"].self_link
    }
  }
}

resource "google_cloud_run_service_iam_member" "frontend_iap_invoker" {
  count    = var.iap_enabled ? 1 : 0
  location = google_cloud_run_v2_service.frontend.location
  project  = google_cloud_run_v2_service.frontend.project
  service  = google_cloud_run_v2_service.frontend.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:service-${data.google_project.this.number}@gcp-sa-iap.iam.gserviceaccount.com"
}

resource "google_cloud_run_service_iam_member" "frontend_public_access" {
  location = google_cloud_run_v2_service.frontend.location
  project  = google_cloud_run_v2_service.frontend.project
  service  = google_cloud_run_v2_service.frontend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_iap_web_backend_service_iam_binding" "frontend" {
  count               = var.iap_enabled ? 1 : 0
  project             = var.project
  web_backend_service = "frontend-${var.environment}-backend-default"
  role                = "roles/iap.httpsResourceAccessor"
  members             = var.iap_members

  depends_on = [module.lb-http-frontend]
}

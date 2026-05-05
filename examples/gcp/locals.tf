locals {
  project     = ""
  region      = "us-west1"
  environment = "prod"
  tag         = "sha-26ab23f"
  backend_env = {
    "AUTH_SERVICES"                    = "ashirt"
    "AUTH_SERVICES_ALLOW_REGISTRATION" = "ashirt"
  }
  min_backend_instances    = 0
  min_frontend_instances   = 0
  min_ocr_worker_instances = 0
  ocr_worker_env = {
    "BACKEND" = "gcp"
  }
  worker_access_key = ""
  worker_secret_key = ""
}

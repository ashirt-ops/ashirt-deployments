locals {
  project        = ""
  region         = "us-west1"
  environment    = "prod"
  tag            = "sha-26ab23f"
  ocr_worker_tag = "sha-76ae36b"
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
  ocr_worker_access_key = ""
  ocr_worker_secret_key = ""
}

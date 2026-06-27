locals {
  region         = "us-west-2"
  environment    = "prod"
  tag            = "sha-26ab23f"
  ocr_worker_tag = "sha-76ae36b"
  ashirt_server_env = {
    "AUTH_SERVICES"                    = "ashirt"
    "AUTH_SERVICES_ALLOW_REGISTRATION" = "ashirt"
  }
  min_ashirt_server_instances = 1
  min_frontend_instances      = 1
  min_ocr_worker_instances    = 1
  ocr_worker_env = {
    "BACKEND" = "aws"
  }
  ocr_worker_access_key = ""
  ocr_worker_secret_key = ""

  # Route53 hosted zone (must already exist) and the application hostname.
  domain          = ""
  frontend_domain = ""

  allow_frontend_cidrs = ["0.0.0.0/0"]
}

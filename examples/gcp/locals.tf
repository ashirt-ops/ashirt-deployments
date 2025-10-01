locals {
  project     = ""
  region      = "us-west1"
  environment = "prod"
  tag         = "sha-26ab23f"
  backend_env = {
    "AUTH_SERVICES"                    = "ashirt"
    "AUTH_SERVICES_ALLOW_REGISTRATION" = "ashirt"
  }
}

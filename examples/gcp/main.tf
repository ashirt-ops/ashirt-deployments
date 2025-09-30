provider "google" {
  project = local.project
  region  = local.region
}

module "gcp" {
  source = "./ashirt-deployments/modules/gcp"

  project     = local.project
  region      = local.region
  environment = local.environment
  tag         = local.tag
  auth        = local.auth
}

provider "google" {
  project = local.project
  region  = local.region
}

module "gcp" {
  source = "./ashirt-deployments/modules/gcp"

  project                = local.project
  region                 = local.region
  environment            = local.environment
  tag                    = local.tag
  backend_env            = local.backend_env
  min_backend_instances  = local.min_backend_instances
  min_frontend_instances = local.min_frontend_instances
}

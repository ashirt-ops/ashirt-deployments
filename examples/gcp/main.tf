provider "google" {
  project = local.project
  region  = local.region
}

module "gcp" {
  source = "./ashirt-deployments/modules/gcp"

  project                  = local.project
  region                   = local.region
  environment              = local.environment
  tag                      = local.tag
  backend_env              = local.backend_env
  min_backend_instances    = local.min_backend_instances
  min_frontend_instances   = local.min_frontend_instances
  min_ocr_worker_instances = local.min_ocr_worker_instances
  ocr_worker_env           = local.ocr_worker_env
  worker_access_key        = local.worker_access_key
  worker_secret_key        = local.worker_secret_key
}

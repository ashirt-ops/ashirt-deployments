provider "aws" {
  region = local.region
}

module "aws" {
  source = "./ashirt-deployments/modules/aws"

  region                      = local.region
  environment                 = local.environment
  tag                         = local.tag
  ocr_worker_tag              = local.ocr_worker_tag
  ashirt_server_env           = local.ashirt_server_env
  min_ashirt_server_instances = local.min_ashirt_server_instances
  min_frontend_instances      = local.min_frontend_instances
  min_ocr_worker_instances    = local.min_ocr_worker_instances
  ocr_worker_env              = local.ocr_worker_env
  ocr_worker_access_key       = local.ocr_worker_access_key
  ocr_worker_secret_key       = local.ocr_worker_secret_key
  domain                      = local.domain
  frontend_domain             = local.frontend_domain
  allow_frontend_cidrs        = local.allow_frontend_cidrs
}

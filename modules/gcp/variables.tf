variable "project" {
  type        = string
  description = "The GCP project name"
}

variable "region" {
  type        = string
  description = "The region to deploy into"
}

variable "db_tier" {
  type        = string
  description = "The tier for the database"
  default     = "db-g1-small"
}

variable "db_edition" {
  type        = string
  description = "The CloudSQL edition for the database"
  default     = "ENTERPRISE"
}

variable "db_availability_type" {
  type        = string
  description = "The availability type for the database"
  default     = "REGIONAL"
}

variable "environment" {
  type        = string
  description = "The name of the deployment environment"
  default     = "prod"
}

variable "tag" {
  type        = string
  description = "The image tag for the containers"
}

variable "ocr_worker_tag" {
  type        = string
  description = "The image tag for the ocr-worker container"
}

variable "ashirt_server_env" {
  type        = map(any)
  description = "Environment variables for the ashirt-server service"
}

variable "min_ashirt_server_instances" {
  type        = number
  description = "The minimum number of ashirt-server instances"
  default     = 0
}


variable "min_frontend_instances" {
  type        = number
  description = "The minimum number of frontend instances"
  default     = 0
}

variable "min_ocr_worker_instances" {
  type        = number
  description = "The minimum number of ocr-worker instances"
  default     = 1
}

variable "ocr_worker_access_key" {
  type        = string
  description = "Access key for the ocr-worker to authenticate against the ashirt-server API"
  sensitive   = true
}

variable "ocr_worker_secret_key" {
  type        = string
  description = "Base64-encoded secret key for the ocr-worker to authenticate against the ashirt-server API"
  sensitive   = true
}

variable "ocr_worker_env" {
  type        = map(any)
  description = "Environment variables for the ocr-worker service"
  default     = {}
}

variable "frontend_domain" {
  type        = string
  description = "The fully-qualified hostname for the frontend (used for the Google-managed SSL certificate and IAP)"
}

variable "iap_members" {
  type        = list(string)
  description = "IAM members granted roles/iap.httpsResourceAccessor on the frontend backend service (e.g. user:foo@example.com, group:eng@example.com, domain:example.com)"
  default     = []
}

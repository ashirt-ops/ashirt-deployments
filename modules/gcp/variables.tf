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

variable "auth" {
  type        = map(any)
  description = ""
}

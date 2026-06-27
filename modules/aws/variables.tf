variable "region" {
  type        = string
  description = "The AWS region to deploy into"
}

variable "environment" {
  type        = string
  description = "The name of the deployment environment. Used as a suffix on resource names."
  default     = "prod"
}

variable "tag" {
  type        = string
  description = "The image tag for the ashirt-server, frontend, and init containers"
}

variable "ocr_worker_tag" {
  type        = string
  description = "The image tag for the ocr-worker container"
}

variable "ashirt_server_env" {
  type        = map(string)
  description = "Additional environment variables for the ashirt-server service"
  default     = {}
}

variable "ocr_worker_env" {
  type        = map(string)
  description = "Additional environment variables for the ocr-worker service"
  default     = {}
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

variable "domain" {
  type        = string
  description = "The Route53 public hosted zone the deployment lives in (e.g. example.com). Must already exist."
}

variable "frontend_domain" {
  type        = string
  description = "The fully-qualified hostname for the frontend (e.g. ashirt.example.com). Must be within var.domain. Used for the ACM certificate and the Route53 alias record."
}

# Networking

variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "az_count" {
  type        = number
  description = "Number of availability zones to spread subnets across. Aurora requires at least 2."
  default     = 2
}

variable "allow_frontend_cidrs" {
  type        = list(string)
  description = "CIDR blocks permitted to reach the public frontend load balancer over HTTPS"
  default     = ["0.0.0.0/0"]
}

# Compute sizing (Fargate). cpu/memory must be a valid Fargate combination:
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html

variable "cpu" {
  type        = number
  description = "CPU units for each ashirt-server, frontend, and init task"
  default     = 512
}

variable "memory" {
  type        = number
  description = "Memory (MiB) for each ashirt-server, frontend, and init task"
  default     = 1024
}

variable "ocr_worker_cpu" {
  type        = number
  description = "CPU units for the ocr-worker task"
  default     = 512
}

variable "ocr_worker_memory" {
  type        = number
  description = "Memory (MiB) for the ocr-worker task"
  default     = 1024
}

variable "min_ashirt_server_instances" {
  type        = number
  description = "Desired number of ashirt-server tasks"
  default     = 1
}

variable "min_frontend_instances" {
  type        = number
  description = "Desired number of frontend tasks"
  default     = 1
}

variable "min_ocr_worker_instances" {
  type        = number
  description = "Desired number of ocr-worker tasks"
  default     = 1
}

# Database (Aurora MySQL Serverless v2)

variable "rds_min_capacity" {
  type        = number
  description = "Minimum Aurora Serverless v2 capacity (ACUs)"
  default     = 0.5
}

variable "rds_max_capacity" {
  type        = number
  description = "Maximum Aurora Serverless v2 capacity (ACUs)"
  default     = 2
}

variable "log_retention_in_days" {
  type        = number
  description = "Retention period for the CloudWatch log group"
  default     = 90
}

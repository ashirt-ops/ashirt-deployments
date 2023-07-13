##########################
# MUST UPDATE BELOW ######
##########################

# Repository hash ( e.g. sha-84dae8b) or pr tag (e.g. pr-678) is used to target a snapshot of the rolling update. `latest` may be used, but is not recommended.
variable "tag" {
  type    = string
  default = "sha-d8e6d60"
}
# Public domain name for application. This must be registered with route53, with a primary public zone created.
variable "domain" {
  type        = string
  description = "Public domain name"
  default     = "example.com"
}
# s3 bucket names to be created for application data, and application environment configuration
variable "appdata" {
  type    = string
  default = "example.com-data"
}
variable "appenv" {
  type    = string
  default = "example.com-env"
}
# Service worker API keys added after initial user setup
variable "WORKER_ACCESS_KEY" {
  type    = string
  default = ""
}
variable "WORKER_SECRET_KEY" {
  type    = string
  default = ""
}

##########################
# MAY UPDATE BELOW #######
##########################
# Enable Maintenance mode. This provisions an EC2 host that can access the database
variable "maintenance_mode" {
  type    = bool
  default = false
}

# Do you want things in private subnets?
variable "private_subnet" {
  type    = bool
  default = false
}

# Enable CKMS?
variable "kms" {
  type    = bool
  default = true
}

variable "region" {
  type    = string
  default = "us-west-2"
}
# Resources for each container. This must follow Fargate sizing described here https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html#
variable "cpu" {
  type    = number
  default = 256
}
variable "mem" {
  type    = number
  default = 512
}
# Application prefix. This can be used for prod/dev deployments.
variable "app_name" {
  type        = string
  description = "Name of your application deployment"
  default     = "ashirt"
}
# Allowlists for the frontend and API interfaces. For production deployments we recommend the API to be exposed publically for operator flexiblitiy
# and the frontend have some network restrictions.
variable "allow_frontend_cidrs" {
  type = list(string)
  #default = ["8.8.8.8/32","4.4.4.4/32"]
  default = ["0.0.0.0/0"]
}
variable "allow_api_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
variable "allow_maintenance_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
# Number of availability zones, subnets, and supporting infra to create. 2 should be fine for most deployments.
variable "az_count" {
  type    = number
  default = 2
}
# Application container port, and nginx port. 
variable "app_port" {
  type    = number
  default = 8000
}
variable "nginx_port" {
  type    = number
  default = 8080
}

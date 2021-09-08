# Data providers

provider "aws" {
  region = var.region
}
data "aws_availability_zones" "az" {}
data "aws_caller_identity" "current" {}

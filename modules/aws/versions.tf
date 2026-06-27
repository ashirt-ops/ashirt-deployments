terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.8"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

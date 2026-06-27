output "frontend_url" {
  description = "The public URL of the ASHIRT frontend."
  value       = module.aws.frontend_url
}

output "frontend_lb_dns_name" {
  description = "DNS name of the public frontend load balancer."
  value       = module.aws.frontend_lb_dns_name
}

output "storage_bucket" {
  description = "Name of the S3 bucket holding ASHIRT evidence."
  value       = module.aws.storage_bucket
}

output "cluster_name" {
  description = "Name of the ECS cluster running the ASHIRT services."
  value       = module.aws.cluster_name
}

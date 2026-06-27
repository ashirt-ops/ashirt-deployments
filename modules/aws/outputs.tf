output "frontend_url" {
  description = "The public URL of the ASHIRT frontend."
  value       = "https://${var.frontend_domain}"
}

output "frontend_lb_dns_name" {
  description = "DNS name of the public frontend load balancer. The Route53 alias for var.frontend_domain already points here."
  value       = aws_lb.frontend.dns_name
}

output "storage_bucket" {
  description = "Name of the S3 bucket holding ASHIRT evidence."
  value       = aws_s3_bucket.ashirt_storage.bucket
}

output "cluster_name" {
  description = "Name of the ECS cluster running the ASHIRT services."
  value       = aws_ecs_cluster.ashirt.name
}

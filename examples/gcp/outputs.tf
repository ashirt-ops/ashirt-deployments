output "frontend_external_ip" {
  description = "External IPv4 of the frontend load balancer; create a DNS A record pointing var.frontend_domain at this address."
  value       = module.gcp.frontend_external_ip
}

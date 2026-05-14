output "frontend_external_ip" {
  description = "The external IPv4 address of the frontend load balancer. Point an A record for var.frontend_domain at this address."
  value       = module.lb-http-frontend.external_ip
}

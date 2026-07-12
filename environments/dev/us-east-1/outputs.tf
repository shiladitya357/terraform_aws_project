output "application_url" {
  description = "Open this URL in a browser after the deployment completes."
  value       = "http://${module.compute.public_alb_dns_name}"
}

output "database_endpoint" {
  value     = module.database.endpoint
  sensitive = true
}

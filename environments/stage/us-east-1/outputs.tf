output "application_url" {
  value = "http://${module.compute.public_alb_dns_name}"
}
output "database_endpoint" {
  value     = module.database.endpoint
  sensitive = true
}

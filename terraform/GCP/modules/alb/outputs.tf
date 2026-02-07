output "load_balancer_ip" {
  description = "IP address of the external load balancer"
  value       = google_compute_forwarding_rule.frontend_http.ip_address
}

output "frontend_backend_service" {
  description = "Frontend backend service name"
  value       = google_compute_backend_service.frontend.name
}

output "backend_backend_service" {
  description = "Backend backend service name"
  value       = var.create_internal_lb ? google_compute_backend_service.backend[0].name : null
}

output "frontend_health_check" {
  description = "Frontend health check name"
  value       = google_compute_health_check.frontend.name
}

output "backend_health_check" {
  description = "Backend health check name"
  value       = var.create_internal_lb ? google_compute_health_check.backend[0].name : null
}

output "url_map" {
  description = "URL map name"
  value       = google_compute_url_map.frontend.name
}

output "frontend_instance_group" {
  description = "Frontend instance group name"
  value       = google_compute_instance_group.frontend.name
}

output "backend_instance_group" {
  description = "Backend instance group name"
  value       = var.create_internal_lb ? google_compute_instance_group.backend[0].name : null
}

output "global_ip_address" {
  description = "Global static IP address (if created)"
  value       = var.create_global_ip ? google_compute_global_address.frontend[0].address : null
}

output "regional_ip_address" {
  description = "Regional static IP address (if created)"
  value       = var.create_regional_ip ? google_compute_address.frontend[0].address : null
}

output "internal_ip_address" {
  description = "Internal static IP address (if created)"
  value       = var.create_internal_lb ? google_compute_address.backend_internal[0].address : null
}

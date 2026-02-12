output "load_balancer_ip" {
  description = "IP address of the external load balancer"
  value       = google_compute_global_forwarding_rule.frontend_http.ip_address
}

output "frontend_backend_service" {
  description = "Frontend backend service name"
  value       = google_compute_backend_service.frontend.name
}

output "backend_backend_service" {
  description = "Backend backend service name"
  value       = google_compute_region_backend_service.backend.name
}

output "frontend_health_check" {
  description = "Frontend health check name"
  value       = google_compute_health_check.frontend.name
}

output "backend_health_check" {
  description = "Backend health check name"
  value       = google_compute_region_health_check.backend.name
}

output "url_map" {
  description = "URL map name"
  value       = google_compute_url_map.frontend.name
}

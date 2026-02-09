output "network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.main.id
}

output "network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.main.name
}

output "frontend_subnet_id" {
  description = "ID of the frontend subnet"
  value       = google_compute_subnetwork.frontend.id
}

output "frontend_subnet_name" {
  description = "Name of the frontend subnet"
  value       = google_compute_subnetwork.frontend.name
}

output "backend_subnet_id" {
  description = "ID of the backend subnet"
  value       = google_compute_subnetwork.backend.id
}

output "backend_subnet_name" {
  description = "Name of the backend subnet"
  value       = google_compute_subnetwork.backend.name
}

output "ansible_subnet_id" {
  description = "ID of the ansible subnet"
  value       = google_compute_subnetwork.ansible.id
}

output "ansible_subnet_name" {
  description = "Name of the ansible subnet"
  value       = google_compute_subnetwork.ansible.name
}

output "ilb_subnet_id" {
  description = "ID of the Internal Load Balancer (Proxy-only) subnet"
  value       = google_compute_subnetwork.proxy_only.id
}

output "ilb_subnet_name" {
  description = "Name of the Internal Load Balancer (Proxy-only) subnet"
  value       = google_compute_subnetwork.proxy_only.name
}

output "psa_range_name" {
  description = "Name of the PSA range"
  value       = google_compute_global_address.psa_range.name
}
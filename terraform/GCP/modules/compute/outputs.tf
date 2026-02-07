output "frontend_instance_id" {
  description = "ID of the frontend instance"
  value       = google_compute_instance.frontend.id
}

output "frontend_instance_name" {
  description = "Name of the frontend instance"
  value       = google_compute_instance.frontend.name
}

output "backend_instance_id" {
  description = "ID of the backend instance"
  value       = google_compute_instance.backend.id
}

output "backend_instance_name" {
  description = "Name of the backend instance"
  value       = google_compute_instance.backend.name
}

output "ansible_instance_id" {
  description = "ID of the ansible instance"
  value       = google_compute_instance.ansible.id
}

output "ansible_instance_name" {
  description = "Name of the ansible instance"
  value       = google_compute_instance.ansible.name
}

output "service_account_email" {
  description = "Email of the compute service account"
  value       = google_service_account.compute.email
}

output "frontend_security_group_id" {
  description = "Frontend security group (using tags in GCP)"
  value       = "frontend"
}

output "backend_security_group_id" {
  description = "Backend security group (using tags in GCP)"
  value       = "backend"
}

output "ansible_security_group_id" {
  description = "Ansible security group (using tags in GCP)"
  value       = "ansible"
}

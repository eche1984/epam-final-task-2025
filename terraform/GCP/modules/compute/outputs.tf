output "ansible_instance_id" {
  description = "ID of the ansible instance"
  value       = google_compute_instance.ansible.id
}

output "ansible_instance_name" {
  description = "Name of the ansible instance"
  value       = google_compute_instance.ansible.name
}

output "frontend_mig_name" {
  description = "Frontend Manage Instance Group name"
  value       = google_compute_region_instance_group_manager.frontend.name
}

output "backend_mig_name" {
  description = "Backend Manage Instance Group name"
  value       = google_compute_region_instance_group_manager.backend.name
}

output "frontend_mig_link" {
  description = "Link to the Frontend Instance Group for the ALB"
  value       = google_compute_region_instance_group_manager.frontend.instance_group
}

output "backend_mig_link" {
  description = "Link to the Backend Instance Group for the ILB"
  value       = google_compute_region_instance_group_manager.backend.instance_group
}

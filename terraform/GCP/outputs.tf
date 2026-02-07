# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.network_id
}

output "vpc_name" {
  description = "Name of the VPC"
  value       = module.vpc.network_name
}

output "frontend_subnet_id" {
  description = "ID of the frontend subnet"
  value       = module.vpc.frontend_subnet_id
}

output "backend_subnet_id" {
  description = "ID of the backend subnet"
  value       = module.vpc.backend_subnet_id
}

output "ansible_subnet_id" {
  description = "ID of the ansible subnet"
  value       = module.vpc.ansible_subnet_id
}

output "ilb_subnet_id" {
  description = "ID of the Internal Load Balancer (Proxy-only) subnet"
  value       = module.vpc.ilb_subnet_id
}

/*
# Compute Outputs
output "frontend_instance_id" {
  description = "ID of the frontend instance"
  value       = module.compute.frontend_instance_id
}

output "frontend_instance_name" {
  description = "Name of the frontend instance"
  value       = module.compute.frontend_instance_name
}

output "backend_instance_id" {
  description = "ID of the backend instance"
  value       = module.compute.backend_instance_id
}

output "backend_instance_name" {
  description = "Name of the backend instance"
  value       = module.compute.backend_instance_name
}

output "ansible_instance_id" {
  description = "ID of the ansible instance"
  value       = module.compute.ansible_instance_id
}

output "ansible_instance_name" {
  description = "Name of the ansible instance"
  value       = module.compute.ansible_instance_name
}

output "frontend_security_group_id" {
  description = "Frontend security group (using tags in GCP)"
  value       = module.compute.frontend_security_group_id
}

output "backend_security_group_id" {
  description = "Backend security group (using tags in GCP)"
  value       = module.compute.backend_security_group_id
}

output "service_account_email" {
  description = "Email of the compute service account"
  value       = module.compute.service_account_email
}

# Database Outputs
output "db_instance_id" {
  description = "ID of the database instance"
  value       = module.sql.db_instance_id
}

output "db_instance_name" {
  description = "Name of the database instance"
  value       = module.sql.db_instance_name
}

output "db_instance_connection_name" {
  description = "Connection name of the database instance"
  value       = module.sql.db_instance_connection_name
}

output "db_instance_ip_address" {
  description = "Private IP address of the database instance"
  value       = module.sql.db_instance_ip_address
}

output "database_name" {
  description = "Name of the database"
  value       = module.sql.database_name
}

output "database_user" {
  description = "Database username"
  value       = module.sql.database_user
}

# Load Balancer Outputs
output "load_balancer_ip" {
  description = "IP address of the load balancer"
  value       = module.alb.load_balancer_ip
}

output "backend_service" {
  description = "Backend service name"
  value       = module.alb.backend_service
}

output "health_check" {
  description = "Health check name"
  value       = module.alb.health_check
}

output "global_ip_address" {
  description = "Global static IP address (if created)"
  value       = module.alb.global_ip_address
}

output "regional_ip_address" {
  description = "Regional static IP address (if created)"
  value       = module.alb.regional_ip_address
}

# Monitoring Outputs
output "monitoring_outputs" {
  description = "Monitoring module outputs"
  value       = var.enable_monitoring ? module.monitoring[0] : null
}
*/
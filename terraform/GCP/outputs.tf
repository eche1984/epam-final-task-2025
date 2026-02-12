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

output "backend_ilb_ip" {
  description = "Internal static IP address"
  value       = module.vpc.backend_ilb_ip
}

# Compute Outputs
output "ansible_instance_id" {
  description = "ID of the ansible instance"
  value       = module.compute.ansible_instance_id
}

output "ansible_instance_name" {
  description = "Name of the ansible instance"
  value       = module.compute.ansible_instance_name
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

output "frontend_backend_service" {
  description = "Frontend backend service name"
  value       = module.alb.frontend_backend_service
}

output "frontend_health_check" {
  description = "Frontend health check name"
  value       = module.alb.frontend_health_check
}

output "backend_service" {
  description = "Backend service name"
  value       = module.alb.backend_backend_service
}

output "health_check" {
  description = "Health check name"
  value       = module.alb.backend_health_check
}
/*
# Monitoring Outputs
output "monitoring_outputs" {
  description = "Monitoring module outputs"
  value       = var.enable_monitoring ? module.monitoring[0] : null
}
*/
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "frontend_instance_private_ip" {
  description = "Private IP of the frontend instance"
  value       = module.ec2.frontend_instance_private_ip
}

output "backend_instance_private_ip" {
  description = "Private IP of the backend instance"
  value       = module.ec2.backend_instance_private_ip
}

output "ansible_instance_private_ip" {
  description = "Private IP of the ansible control node"
  value       = module.ec2.ansible_instance_private_ip
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint"
  value       = module.rds.rds_endpoint
}

output "rds_address" {
  description = "RDS MySQL address"
  value       = module.rds.rds_address
}

output "rds_port" {
  description = "RDS MySQL port"
  value       = module.rds.rds_port
}

output "backend_url" {
  description = "Backend URL for frontend configuration"
  value       = "http://${module.ec2.backend_instance_private_ip}:${var.backend_port}"
}

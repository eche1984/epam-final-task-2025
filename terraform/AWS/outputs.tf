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

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value = module.alb.alb_dns_name
}

# Monitoring outputs
output "cloudwatch_log_groups" {
  description = "CloudWatch log groups for monitoring"
  value = var.enable_monitoring ? {
    frontend = module.monitoring[0].cloudwatch_log_group_frontend
    backend  = module.monitoring[0].cloudwatch_log_group_backend
    ansible  = module.monitoring[0].cloudwatch_log_group_ansible
  } : null
}

output "cloudwatch_alarms" {
  description = "CloudWatch alarms for monitoring"
  value = var.enable_monitoring ? {
    ec2_cpu_alarms             = module.monitoring[0].ec2_cpu_alarms
    rds_cpu_alarm              = module.monitoring[0].rds_cpu_alarm
    rds_storage_alarm          = module.monitoring[0].rds_storage_alarm
    rds_connections_alarm      = module.monitoring[0].rds_connections_alarm
    alb_5xx_alarm              = module.monitoring[0].alb_5xx_alarm
    alb_response_time_alarm    = module.monitoring[0].alb_response_time_alarm
    alb_unhealthy_hosts_alarm  = module.monitoring[0].alb_unhealthy_hosts_alarm
  } : null
}

output "monitoring_sns_topic_arn" {
  description = "SNS topic ARN for monitoring alerts"
  value = var.enable_monitoring && var.enable_email_notifications ? module.monitoring[0].sns_topic_arn : null
}

output "monitoring_dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value = var.enable_monitoring ? module.monitoring[0].dashboard_url : null
}
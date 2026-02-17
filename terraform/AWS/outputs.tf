output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "external_alb_dns_name" {
  description = "DNS name of the external Application Load Balancer"
  value = module.alb.external_alb_dns
}

output "internal_alb_dns_name" {
  description = "DNS name of the internal Application Load Balancer"
  value = module.alb.internal_alb_dns
}

output "rds_address" {
  description = "RDS instance address"
  value       = module.rds.rds_address
}

output "ansible_instance_private_ip" {
  description = "Private IP of the ansible control node"
  value       = module.ec2.ansible_instance_private_ip
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
    asg_cpu_alarms             = module.monitoring[0].asg_cpu_high
    ansible_cpu_alarms         = module.monitoring[0].ansible_cpu_high
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

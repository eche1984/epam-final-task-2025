output "cloudwatch_log_group_frontend" {
  description = "CloudWatch log group name for frontend instance"
  value       = aws_cloudwatch_log_group.frontend_logs.name
}

output "cloudwatch_log_group_backend" {
  description = "CloudWatch log group name for backend instance"
  value       = aws_cloudwatch_log_group.backend_logs.name
}

output "cloudwatch_log_group_ansible" {
  description = "CloudWatch log group name for ansible instance"
  value       = aws_cloudwatch_log_group.ansible_logs.name
}

output "asg_cpu_high" {
  description = "ASG EC2 CPU alarm names"
  value = {
    for instance_name, alarm in aws_cloudwatch_metric_alarm.asg_cpu_high : instance_name => alarm.alarm_name
  }
}

output "ansible_cpu_high" {
  description = "Ansible EC2 CPU alarm name"
  value = aws_cloudwatch_metric_alarm.ansible_cpu_high.alarm_name
}

output "rds_cpu_alarm" {
  description = "RDS CPU high alarm name"
  value       = aws_cloudwatch_metric_alarm.rds_cpu_high.alarm_name
}

output "rds_storage_alarm" {
  description = "RDS storage low alarm name"
  value       = aws_cloudwatch_metric_alarm.rds_storage_low.alarm_name
}

output "rds_connections_alarm" {
  description = "RDS connections high alarm name"
  value       = aws_cloudwatch_metric_alarm.rds_connections_high.alarm_name
}

output "alb_5xx_alarm" {
  description = "ALB 5XX errors alarm name"
  value       = aws_cloudwatch_metric_alarm.alb_5xx_errors.alarm_name
}

output "alb_response_time_alarm" {
  description = "ALB response time alarm name"
  value       = aws_cloudwatch_metric_alarm.alb_target_response_time.alarm_name
}

output "alb_unhealthy_hosts_alarm" {
  description = "ALB unhealthy hosts alarm name"
  value       = aws_cloudwatch_metric_alarm.alb_unhealthy_hosts.alarm_name
}

output "sns_topic_arn" {
  description = "SNS topic ARN for monitoring alerts"
  value       = var.enable_email_notifications ? aws_sns_topic.monitoring_alerts[0].arn : ""
}

output "dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.monitoring_dashboard.dashboard_name}"
}

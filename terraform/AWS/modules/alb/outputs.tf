output "external_alb_id" {
  description = "ID of the External Application Load Balancer"
  value       = aws_lb.frontend_alb.id
}

output "external_alb_arn" {
  description = "ARN of the External Application Load Balancer"
  value       = aws_lb.frontend_alb.arn
}

output "external_alb_dns" {
  description = "DNS name of the External Application Load Balancer"
  value       = aws_lb.frontend_alb.dns_name
}

output "external_alb_zone_id" {
  description = "Zone ID of the External Application Load Balancer"
  value       = aws_lb.frontend_alb.zone_id
}

output "external_alb_arn_suffix" {
  description = "ARN suffix of the External Application Load Balancer"
  value       = aws_lb.frontend_alb.arn_suffix
}

output "internal_alb_dns" {
  description = "DNS name of the Internal Application Load Balancer"
  value       = aws_lb.backend_ilb.dns_name
}

output "internal_alb_arn_suffix" {
  description = "ARN suffix of the Internal Application Load Balancer"
  value       = aws_lb.backend_ilb.arn_suffix
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "frontend_tg_arn" {
  description = "ARN of the frontend target group"
  value       = aws_lb_target_group.frontend_tg.arn
}

output "frontend_tg_arn_suffix" {
  description = "ARN suffix of the frontend target group"
  value       = aws_lb_target_group.frontend_tg.arn_suffix
}

output "backend_tg_arn" {
  description = "ARN of the backend target group"
  value       = aws_lb_target_group.backend_tg.arn
}

output "backend_tg_arn_suffix" {
  description = "ARN suffix of the backend target group"
  value       = aws_lb_target_group.backend_tg.arn_suffix
}

output "ssm_parameter_frontend_url" {
  description = "Frontend URL stored as AWS SSM Parameter"
  value       = aws_ssm_parameter.frontend_url.arn
}

output "ssm_parameter_backend_url" {
  description = "Backend URL stored as AWS SSM Parameter"
  value       = aws_ssm_parameter.backend_url.arn
}

output "ssm_parameter_frontend_port" {
  description = "Frontend port stored as AWS SSM Parameter"
  value       = aws_ssm_parameter.frontend_port.arn
}

output "ssm_parameter_backend_port" {
  description = "Backend port stored as AWS SSM Parameter"
  value       = aws_ssm_parameter.backend_port.arn
}

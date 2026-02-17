variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "frontend_asg_name" {
  description = "Name of the Frontend ASG"
  type        = string
}

variable "backend_asg_name" {
  description = "Name of the Backend ASG"
  type        = string
}

variable "ansible_instance_id" {
  description = "EC2 instance ID for ansible"
  type        = string
}

variable "rds_instance_id" {
  description = "RDS instance identifier"
  type        = string
}

variable "external_alb_arn_suffix" {
  description = "External ALB ARN suffix for CloudWatch metrics"
  type        = string
}

variable "internal_alb_arn_suffix" {
  description = "Internal ALB ARN suffix for CloudWatch metrics"
  type        = string
}

variable "alb_target_group_arn_suffix" {
  description = "ALB target group ARN suffix for CloudWatch metrics"
  type        = string
}

variable "enable_email_notifications" {
  description = "Enable email notifications for alerts"
  type        = bool
}

variable "notification_email" {
  description = "Email address for alert notifications"
  type        = string
}

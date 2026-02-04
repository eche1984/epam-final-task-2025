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

variable "frontend_instance_id" {
  description = "EC2 instance ID for frontend"
  type        = string
}

variable "backend_instance_id" {
  description = "EC2 instance ID for backend"
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

variable "alb_arn_suffix" {
  description = "ALB ARN suffix for CloudWatch metrics"
  type        = string
}

variable "alb_target_group_arn_suffix" {
  description = "ALB target group ARN suffix for CloudWatch metrics"
  type        = string
}

variable "enable_email_notifications" {
  description = "Enable email notifications for alerts"
  type        = bool
  default     = false
}

variable "notification_email" {
  description = "Email address for alert notifications"
  type        = string
  default     = ""
}

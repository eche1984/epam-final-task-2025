variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "frontend_subnet_id" {
  description = "ID of the frontend subnet (public)"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB (requires at least 2 subnets in different AZs)"
  type        = list(string)
}

variable "frontend_instance_id" {
  description = "ID of the frontend EC2 instance"
  type        = string
}

variable "frontend_security_group_id" {
  description = "Security group ID of the frontend EC2 instance"
  type        = string
}

variable "frontend_port" {
  description = "Port for frontend application"
  type        = number
  default     = 3000
}

variable "health_check_path" {
  description = "Health check path for the target group"
  type        = string
  default     = "/"
}

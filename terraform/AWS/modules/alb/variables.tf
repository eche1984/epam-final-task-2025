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

variable "backend_subnet_ids" {
  description = "List of backend subnet IDs for internal ALB"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB (requires at least 2 subnets in different AZs)"
  type        = list(string)
}

variable "backend_ilb_sg_id" {
  description = "Security group ID of the backend ALB"
  type        = string
}

variable "frontend_sg_id" {
  description = "Security group ID of the frontend EC2 instance"
  type        = string
}

variable "frontend_port" {
  description = "Port for frontend application"
  type        = number
}

variable "backend_port" {
  description = "Port for backend application"
  type        = number
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "alb_public_subnet_cidr_1" {
  description = "CIDR block for first public subnet (for ALB high availability)"
  type        = string
}

variable "alb_public_subnet_cidr_2" {
  description = "CIDR block for second public subnet (for ALB high availability)"
  type        = string
}

variable "frontend_subnet_cidr" {
  description = "CIDR block for frontend subnet"
  type        = string
}

variable "backend_subnet_cidr" {
  description = "CIDR block for backend subnet"
  type        = string
}

variable "ansible_subnet_cidr" {
  description = "CIDR block for ansible subnet"
  type        = string
}

variable "db_subnet_group_cidr_1" {
  description = "CIDR block for DB subnet group"
  type        = string
}

variable "db_subnet_group_cidr_2" {
  description = "CIDR block for DB subnet group"
  type        = string
}
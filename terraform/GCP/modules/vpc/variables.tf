variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC (not used in GCP but kept for compatibility)"
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

variable "ilb_private_subnet_cidr" {
  description = "CIDR block for Internal Load Balancer subnet"
  type        = string
}

variable "db_subnet_cidr" {
  description = "CIDR block for database subnet"
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

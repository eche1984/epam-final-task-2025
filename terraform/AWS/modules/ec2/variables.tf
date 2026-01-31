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
  description = "ID of the frontend subnet"
  type        = string
}

variable "backend_subnet_id" {
  description = "ID of the backend subnet"
  type        = string
}

variable "ansible_subnet_id" {
  description = "ID of the ansible subnet"
  type        = string
}

variable "ansible_subnet_cidr" {
  description = "CIDR block of ansible subnet"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
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

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1)"
  type        = string
}
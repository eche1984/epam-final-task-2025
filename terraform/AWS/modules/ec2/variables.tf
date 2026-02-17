variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "region" {
  description = "AWS region"
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

variable "backend_subnet_ids" {
  description = "IDs of the backend subnets"
  type        = list(string)
}

/*
variable "frontend_subnet_ids" {
  description = "IDs of the backend subnets"
  type        = list(string)
}
*/
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

variable "frontend_max_size" {
  description = "Maximum number of frontend instances"
  type        = number
}

variable "backend_max_size" {
  description = "Maximum number of backend instances"
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

variable "backend_tg_arn" {
  description = "ARN of the backend target group"
  type        = string
}

variable "frontend_tg_arn" {
  description = "ARN of the frontend target group"
  type        = string
}

variable "backend_sg_id" {
  description = "ID of the backend Security Group"
  type        = string
}

variable "frontend_sg_id" {
  description = "ID of the frontend Security Group"
  type        = string
}

variable "ansible_sg_id" {
  description = "ID of the ansible Security Group"
  type        = string
}

variable "db_password_parameter_name" {
  description = "Optional SSM Parameter Store name (SecureString) that contains the DB password"
  type        = string
}

variable "ssm_parameter_frontend_url" {
  description = "Frontend URL stored as AWS SSM Parameter"
  type        = string
}

variable "ssm_parameter_backend_url" {
  description = "Backend URL stored as AWS SSM Parameter"
  type        = string
}

variable "ssm_parameter_frontend_port" {
  description = "Frontend port stored as AWS SSM Parameter"
  type        = string
}

variable "ssm_parameter_backend_port" {
  description = "Backend port stored as AWS SSM Parameter"
  type        = string
}
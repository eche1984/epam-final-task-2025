variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
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

variable "ami_id" {
  description = "AMI ID for EC2 instances (Ubuntu 22.04 LTS)"
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

variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "db_username" {
  description = "Username for the database"
  type        = string
}

variable "mysql_version" {
  description = "MySQL engine version"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "ec2_allocated_storage" {
  description = "Allocated storage in GB for EC2 instance"
  type        = number
}

variable "ec2_storage_type" {
  description = "Storage type (gp2, gp3, io1) for EC2 instance"
  type        = string
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GB for RDS instance"
  type        = number
}

variable "rds_storage_type" {
  description = "Storage type (gp2, gp3, io1) for RDS instance"
  type        = string
}
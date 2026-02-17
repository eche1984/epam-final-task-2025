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

variable "backend_sg_id" {
  description = "Security group ID of the backend"
  type        = string
}

variable "ansible_sg_id" {
  description = "Security group ID of the ansible"
  type        = string
}

variable "db_subnet_ids" {
  description = "List of database subnet IDs (for RDS subnet group)"
  type        = list(string)
}

variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "db_username" {
  description = "Username for the database"
  type        = string
}

variable "db_password_parameter_name" {
  description = "Optional SSM Parameter Store name (SecureString) that contains the DB password"
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

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1)"
  type        = string
}


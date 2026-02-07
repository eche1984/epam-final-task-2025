# GCP Project and Region Configuration
variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "zone" {
  description = "GCP Zone"
  type        = string
}

# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
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

# Application Configuration
variable "frontend_port" {
  description = "Port for frontend application"
  type        = number
}

variable "backend_port" {
  description = "Port for backend application"
  type        = number
}

/*
# Compute Configuration
variable "machine_type" {
  description = "Machine type for instances"
  type        = string
}

variable "image" {
  description = "Source image for instances"
  type        = string
}

variable "allocated_storage" {
  description = "Disk size in GB for GCE instances"
  type        = number
}

variable "storage_type" {
  description = "Disk type for GCE instances"
  type        = string
}

variable "ssh_user" {
  description = "SSH username"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection"
  type        = bool
  default     = false
}

# Database Configuration
variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "mysql_version" {
  description = "MySQL version"
  type        = string
}

variable "db_instance_class" {
  description = "Database instance class (tier)"
  type        = string
}

variable "db_allocated_storage" {
  description = "Disk size in GB for DB instances"
  type        = number
}

variable "db_storage_type" {
  description = "Disk type for DB instances"
  type        = string
}

variable "max_connections" {
  description = "Maximum database connections"
  type        = string
  default     = "100"
}

# Load Balancer Configuration
variable "ssl_certificate" {
  description = "SSL certificate ID (optional)"
  type        = string
  default     = ""
}

variable "create_global_ip" {
  description = "Whether to create a global static IP"
  type        = bool
  default     = false
}

variable "create_regional_ip" {
  description = "Whether to create a regional static IP"
  type        = bool
  default     = false
}

# Monitoring Configuration
variable "enable_monitoring" {
  description = "Whether to enable monitoring"
  type        = bool
  default     = false
}

variable "sql_storage_threshold" {
  description = "Storage threshold for SQL instance in bytes"
  type        = number
  default     = 1073741824 # 1GB
}

variable "enable_email_notifications" {
  description = "Whether to enable email notifications"
  type        = bool
  default     = false
}

variable "notification_email" {
  description = "Email address for notifications"
  type        = string
  default     = ""
}
*/
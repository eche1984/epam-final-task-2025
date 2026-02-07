variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
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

variable "network_id" {
  description = "ID of the VPC network"
  type        = string
}

variable "allocated_ip_range" {
  description = "Allocated IP range for private IP"
  type        = string
  default     = ""
}

variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password_secret_name" {
  description = "Database password stored in GCP Secret Manager"
  type        = string  
}

variable "mysql_version" {
  description = "MySQL version"
  type        = string
  default     = "MYSQL_8_0"
}

variable "db_instance_class" {
  description = "Database instance class (tier)"
  type        = string
  default     = "db-n1-standard-1"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "storage_type" {
  description = "Storage type"
  type        = string
  default     = "PD_SSD"
}

variable "backup_start_time" {
  description = "Backup start time"
  type        = string
  default     = "03:00"
}

variable "max_connections" {
  description = "Maximum database connections"
  type        = string
  default     = "100"
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection"
  type        = bool
  default     = false
}

variable "backend_service_account_email" {
  description = "Service account email for backend instance"
  type        = string
}

variable "ansible_service_account_email" {
  description = "Service account email for ansible instance"
  type        = string
}

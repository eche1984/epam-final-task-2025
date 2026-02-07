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

variable "frontend_instance_name" {
  description = "Name of the frontend instance"
  type        = string
}

variable "backend_instance_name" {
  description = "Name of the backend instance"
  type        = string
}

variable "ansible_instance_name" {
  description = "Name of the ansible instance"
  type        = string
}

variable "sql_instance_name" {
  description = "Name of the SQL instance"
  type        = string
}

variable "load_balancer_name" {
  description = "Name of the load balancer (optional)"
  type        = string
  default     = ""
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

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

variable "frontend_mig_name" {
  description = "Name of the frontend Managed Instance Group"
  type        = string
}

variable "frontend_forwarding_rule_name" {
  description = "Name of the frontend forwarding rule"
  type        = string
}

variable "frontend_backend_service" {
  description = "Name of the frontend backend service"
  type        = string
}

variable "backend_mig_name" {
  description = "Name of the backend Managed Instance Group"
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

variable "max_connections" {
  description = "Maximum database connections"
  type        = number
}

variable "sql_storage_threshold_pct" {
  description = "Storage threshold for SQL instance as percentage (0.0-1.0)"
  type        = number
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

variable "load_balancer_ip" {
  description = "Load balancer IP address"
  type        = string
}

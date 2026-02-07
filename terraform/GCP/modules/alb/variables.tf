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

variable "zone" {
  description = "GCP zone"
  type        = string
}

variable "frontend_instance_id" {
  description = "ID of the frontend instance from compute module"
  type        = string
}

variable "backend_instance_id" {
  description = "ID of the backend instance from compute module"
  type        = string
}

variable "frontend_port" {
  description = "Port for frontend application"
  type        = number
  default     = 8080
}

variable "backend_port" {
  description = "Port for backend application"
  type        = number
  default     = 3000
}

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

variable "create_internal_lb" {
  description = "Whether to create internal load balancer for backend"
  type        = bool
  default     = false
}

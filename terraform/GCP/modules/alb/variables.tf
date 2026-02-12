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

variable "network_id" {
  description = "Network ID"
  type        = string
}

variable "backend_subnet_id" {
  description = "Backend subnet ID"
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

/*variable "ssl_certificate" {
  description = "SSL certificate ID (optional)"
  type        = string
  default     = ""
}*/

variable "static_ip_address" {
  description = "Static IP address for the frontend"
  type        = string
}

variable "internal_ip_address" {
  description = "Internal IP address for the backend"
  type        = string
}

variable "frontend_mig_link" {
  description = "Frontend Managed Instance Group link to ALB"
  type        = string
}

variable "backend_mig_link" {
  description = "Backend Managed Instance Group link to ILB"
  type        = string
}
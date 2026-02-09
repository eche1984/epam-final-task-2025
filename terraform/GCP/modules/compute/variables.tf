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

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "frontend_subnet_name" {
  description = "Name of the frontend subnet"
  type        = string
}

variable "backend_subnet_name" {
  description = "Name of the backend subnet"
  type        = string
}

variable "ansible_subnet_name" {
  description = "Name of the ansible subnet"
  type        = string
}

variable "ansible_subnet_cidr" {
  description = "CIDR block for ansible subnet"
  type        = string
}

variable "zone" {
  description = "GCP zone"
  type        = string
}

variable "machine_type" {
  description = "Machine type for instances"
  type        = string
  default     = "e2-medium"
}

variable "image" {
  description = "Source image for instances"
  type        = string
  default     = "debian-cloud/debian-11"
}

variable "allocated_storage" {
  description = "Disk size in GB"
  type        = number
  default     = 20
}

variable "disk_type" {
  description = "Disk type"
  type        = string
  default     = "pd-standard"
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

variable "deletion_protection" {
  description = "Whether to enable deletion protection"
  type        = bool
  default     = false
}

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "epam-finaltask-tfstate-bucket"
    prefix = "movie-analyst"
  }
}

provider "google" {
  project = var.gcp_project_id  
  region  = var.region
  zone    = var.zone
}

locals {
  env_name = terraform.workspace

  # Name of the Secret Manager secret that stores the DB password.
  # NOTE: The value of this secret is created/managed by Terraform,
  # but in production you might want to manage it externally.
  db_password_secret_name = "${var.project_name}-${local.env_name}-db-password"
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name               = var.project_name
  environment                = local.env_name
  region                     = var.region
  vpc_cidr                   = var.vpc_cidr
  frontend_subnet_cidr       = var.frontend_subnet_cidr
  backend_subnet_cidr        = var.backend_subnet_cidr
  ansible_subnet_cidr        = var.ansible_subnet_cidr  
  ilb_private_subnet_cidr    = var.ilb_private_subnet_cidr  
  db_subnet_cidr             = var.db_subnet_cidr
  frontend_port              = var.frontend_port
  backend_port               = var.backend_port
}

# Compute Module
module "compute" {
  source = "./modules/compute"

  project_name         = var.project_name
  project_id           = var.gcp_project_id  
  environment          = local.env_name
  network_name         = module.vpc.network_name
  frontend_subnet_name = module.vpc.frontend_subnet_name
  backend_subnet_name  = module.vpc.backend_subnet_name
  ansible_subnet_name  = module.vpc.ansible_subnet_name
  ansible_subnet_cidr  = var.ansible_subnet_cidr  
  zone                 = var.zone
  machine_type         = var.machine_type
  image                = var.image
  allocated_storage    = var.allocated_storage
  disk_type            = var.disk_type
  frontend_port        = var.frontend_port
  backend_port         = var.backend_port
  deletion_protection  = var.deletion_protection
}

# SQL Module
module "sql" {
  source = "./modules/sql"

  project_name                    = var.project_name
  project_id                      = var.gcp_project_id
  environment                     = local.env_name
  region                          = var.region
  network_id                      = module.vpc.network_id
  allocated_ip_range              = module.vpc.psa_range_name
  db_name                         = var.db_name
  db_username                     = var.db_username  
  db_password_secret_name         = local.db_password_secret_name  
  mysql_version                   = var.mysql_version
  db_instance_class               = var.db_tier
  allocated_storage               = var.db_allocated_storage
  storage_type                    = var.db_disk_type
  max_connections                 = var.max_connections
  deletion_protection             = var.deletion_protection

  depends_on = [module.compute]
}
/*
# Load Balancer Module
module "alb" {
  source = "./modules/alb"

  project_name          = var.project_name
  environment           = local.env_name
  region                = var.region
  zone                  = var.zone
  frontend_instance_id  = module.compute.frontend_instance_id
  backend_instance_id   = module.compute.backend_instance_id
  frontend_port         = var.frontend_port
  backend_port          = var.backend_port
  ssl_certificate       = var.ssl_certificate
  create_global_ip      = var.create_global_ip
  create_regional_ip    = var.create_regional_ip
  create_internal_lb    = var.create_internal_lb  

  depends_on = [module.compute]
}

# Monitoring Module
module "monitoring" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/monitoring"

  project_name           = var.project_name
  project_id             = var.gcp_project_id
  environment            = local.env_name
  frontend_instance_name = module.compute.frontend_instance_name
  backend_instance_name  = module.compute.backend_instance_name
  ansible_instance_name  = module.compute.ansible_instance_name
  sql_instance_name      = module.sql.db_instance_name
  load_balancer_name     = module.alb.frontend_backend_service
  sql_storage_threshold  = var.sql_storage_threshold
  enable_email_notifications = var.enable_email_notifications
  notification_email     = var.notification_email

  depends_on = [module.compute, module.sql, module.alb]
}
*/
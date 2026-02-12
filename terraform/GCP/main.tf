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

  project_name          = var.project_name  
  project_id            = var.gcp_project_id  
  environment           = local.env_name
  network_name          = module.vpc.network_name
  frontend_subnet_name  = module.vpc.frontend_subnet_name
  backend_subnet_name   = module.vpc.backend_subnet_name
  ansible_subnet_name   = module.vpc.ansible_subnet_name
  ansible_subnet_cidr   = var.ansible_subnet_cidr  
  zone                  = var.zone
  region                = var.region
  machine_type          = var.machine_type
  image                 = var.image
  allocated_storage     = var.allocated_storage
  disk_type             = var.disk_type
  frontend_port         = var.frontend_port
  backend_port          = var.backend_port
  backend_ilb_ip        = module.vpc.backend_ilb_ip  
  deletion_protection   = var.deletion_protection
  frontend_max_replicas = var.frontend_max_replicas
  backend_max_replicas  = var.backend_max_replicas
  ansible_sa_email      = google_service_account.ansible_sa.email
  compute_sa_email      = google_service_account.compute_sa.email
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
}

# Load Balancer Module
module "alb" {
  source = "./modules/alb"

  project_name           = var.project_name
  environment            = local.env_name
  region                 = var.region
  zone                   = var.zone
  network_id             = module.vpc.network_id
  backend_subnet_id      = module.vpc.backend_subnet_id
  frontend_port          = var.frontend_port
  backend_port           = var.backend_port  
  frontend_mig_link      = module.compute.frontend_mig_link
  backend_mig_link       = module.compute.backend_mig_link
  static_ip_address      = module.vpc.frontend_external_ip
  internal_ip_address    = module.vpc.backend_ilb_ip
}
/*
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
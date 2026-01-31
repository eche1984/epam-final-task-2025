terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket  = "epam-practicaltask-tfstate-bucket"
    key     = "movie-analyst/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
    # No locking mechanism, this is a testing/learning environment
  }

}

provider "aws" {
  region = var.aws_region
}

locals {
  env_name = terraform.workspace

  # Name of the SSM Parameter Store (SecureString) that stores the DB password.
  # NOTE: The value of this parameter is created/managed outside of Terraform,
  # so the secret is never stored in tfvars or in the Terraform state.
  db_password_parameter_name = "/${var.project_name}/${terraform.workspace}/db_password"
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name              = var.project_name
  environment               = local.env_name
  vpc_cidr                  = var.vpc_cidr
  alb_public_subnet_cidr_1  = var.alb_public_subnet_cidr_1
  alb_public_subnet_cidr_2  = var.alb_public_subnet_cidr_2
  frontend_subnet_cidr      = var.frontend_subnet_cidr
  backend_subnet_cidr       = var.backend_subnet_cidr
  ansible_subnet_cidr       = var.ansible_subnet_cidr
  db_subnet_group_cidr_1    = var.db_subnet_group_cidr_1
  db_subnet_group_cidr_2    = var.db_subnet_group_cidr_2
}

# EC2 Module
module "ec2" {
  source = "./modules/ec2"

  project_name         = var.project_name
  environment          = local.env_name
  vpc_id               = module.vpc.vpc_id
  frontend_subnet_id   = module.vpc.frontend_subnet_id
  backend_subnet_id    = module.vpc.backend_subnet_id
  ansible_subnet_id    = module.vpc.ansible_subnet_id
  ansible_subnet_cidr  = var.ansible_subnet_cidr
  ami_id               = var.ami_id
  instance_type        = var.instance_type
  allocated_storage    = var.ec2_allocated_storage
  storage_type         = var.ec2_storage_type
  frontend_port        = var.frontend_port
  backend_port         = var.backend_port
}

# RDS Module
module "rds" {
  source = "./modules/rds"

  project_name                = var.project_name
  environment                 = local.env_name
  vpc_id                      = module.vpc.vpc_id
  backend_security_group_id   = module.ec2.backend_security_group_id
  frontend_subnet_cidr        = var.frontend_subnet_cidr
  backend_subnet_cidr         = var.backend_subnet_cidr
  ansible_subnet_cidr         = var.ansible_subnet_cidr
  db_subnet_ids               = module.vpc.db_subnet_ids[*]
  db_name                     = var.db_name
  db_username                 = var.db_username
  db_password_parameter_name  = local.db_password_parameter_name
  mysql_version               = var.mysql_version
  db_instance_class           = var.db_instance_class
  allocated_storage           = var.rds_allocated_storage
  storage_type                = var.rds_storage_type
}

# ALB Module - Must be deployed BEFORE the movie-analyst app is up
module "alb" {
  source = "./modules/alb"

  project_name               = var.project_name
  environment                = local.env_name
  vpc_id                     = module.vpc.vpc_id
  frontend_subnet_id         = module.vpc.frontend_subnet_id
  public_subnet_ids          =  module.vpc.public_subnet_ids
  frontend_instance_id       = module.ec2.frontend_instance_id
  frontend_security_group_id = module.ec2.frontend_security_group_id
  frontend_port              = var.frontend_port

  depends_on = [module.ec2]
}

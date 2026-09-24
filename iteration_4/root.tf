terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Service     = var.service
      ManagedBy   = "terraform"
    }
  }
}

module "networking" {
  source              = "./modules/networking"
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  app_subnet_cidrs    = var.app_subnet_cidrs
  db_subnet_cidrs     = var.db_subnet_cidrs
}

module "security_groups" {
  source      = "./modules/security_groups"
  environment = var.environment
  service     = var.service
  vpc_id      = module.networking.vpc_id
  app_port    = var.app_port
  db_port     = var.db_port
}

module "ecs_app" {
  source             = "./modules/ecs_app"
  environment        = var.environment
  service            = var.service
  vpc_id             = module.networking.vpc_id
  app_subnets        = module.networking.private_app_subnets
  alb_sg_id          = module.security_groups.alb_sg_id
  ecs_sg_id          = module.security_groups.ecs_sg_id
  app_port           = var.app_port
  container_image    = var.container_image
  desired_count      = var.desired_count
  task_cpu           = var.task_cpu
  task_memory        = var.task_memory
  log_retention_days = var.log_retention_days
  aws_region         = var.aws_region
}

module "database" {
  source                = "./modules/database"
  environment           = var.environment
  service               = var.service
  vpc_id                = module.networking.vpc_id
  db_subnets            = module.networking.private_db_subnets
  db_sg_id              = module.security_groups.db_sg_id
  db_name               = var.db_name
  db_username           = var.db_username
  db_instance_class     = var.db_instance_class
  backup_retention_days = var.backup_retention_days
  deletion_protection   = var.deletion_protection
}

module "alb" {
  source              = "./modules/alb"
  environment         = var.environment
  service             = var.service
  vpc_id              = module.networking.vpc_id
  public_subnets      = module.networking.public_subnets
  alb_sg_id           = module.security_groups.alb_sg_id
  target_group_arn    = module.ecs_app.target_group_arn
  enable_https        = var.enable_https
  certificate_arn     = var.certificate_arn
  log_bucket_name     = var.alb_log_bucket_name
  deletion_protection = var.alb_deletion_protection
}

output "alb_dns_name" {
  description = "DNS name of the public application load balancer"
  value       = module.alb.dns_name
}

output "db_endpoint" {
  description = "Private endpoint for the PostgreSQL database"
  value       = module.database.endpoint
}

output "db_master_secret_arn" {
  description = "Secrets Manager secret managed by RDS for the database master credentials"
  value       = module.database.master_secret_arn
}

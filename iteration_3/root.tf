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
  region = "eu-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "test"
}

variable "service" {
  description = "Service name"
  type        = string
  default     = "nginx"
}

module "networking" {
  source      = "./modules/networking"
  environment = var.environment
}

module "security_groups" {
  source      = "./modules/security_groups"
  environment = var.environment
  service     = var.service
  vpc_id      = module.networking.vpc_id
}

module "ecs_app" {
  source      = "./modules/ecs_app"
  environment = var.environment
  service     = var.service
  vpc_id      = module.networking.vpc_id
  app_subnets = module.networking.private_app_subnets
  alb_sg_id   = module.security_groups.alb_sg_id
  ecs_sg_id   = module.security_groups.ecs_sg_id
}

module "database" {
  source      = "./modules/database"
  environment = var.environment
  service     = var.service
  vpc_id      = module.networking.vpc_id
  db_subnets  = module.networking.private_db_subnets
  ecs_sg_id   = module.security_groups.ecs_sg_id
  db_sg_id    = module.security_groups.db_sg_id
}

module "alb" {
  source              = "./modules/alb"
  environment         = var.environment
  service             = var.service
  vpc_id              = module.networking.vpc_id
  public_subnets      = module.networking.public_subnets
  alb_sg_id           = module.security_groups.alb_sg_id
  target_group_arn    = module.ecs_app.target_group_arn
}

output "alb_dns_name" {
  description = "DNS name of the public ALB"
  value       = module.alb.dns_name
}

output "db_endpoint" {
  description = "Endpoint for the PostgreSQL database"
  value       = module.database.endpoint
}

variable "environment" {
  type = string
}

variable "service" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "db_subnets" {
  type = list(string)
}

variable "db_sg_id" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "backup_retention_days" {
  type = number
}

variable "deletion_protection" {
  type = bool
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-${var.service}-db-subnets"
  subnet_ids = var.db_subnets
}

resource "aws_db_instance" "main" {
  identifier                  = "${var.environment}-${var.service}-db"
  allocated_storage           = 20
  max_allocated_storage       = 100
  storage_type                = "gp3"
  storage_encrypted           = true
  engine                      = "postgres"
  engine_version              = "16"
  instance_class              = var.db_instance_class
  db_name                     = var.db_name
  username                    = var.db_username
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.main.name
  vpc_security_group_ids      = [var.db_sg_id]
  publicly_accessible         = false
  multi_az                    = true
  backup_retention_period     = var.backup_retention_days
  deletion_protection         = var.deletion_protection
  skip_final_snapshot         = var.deletion_protection ? false : true
  final_snapshot_identifier   = var.deletion_protection ? "${var.environment}-${var.service}-final" : null
  copy_tags_to_snapshot       = true
  auto_minor_version_upgrade  = true

  tags = {
    Name = "${var.environment}-${var.service}-db"
  }
}

output "endpoint" {
  value = aws_db_instance.main.address
}

output "master_secret_arn" {
  value = aws_db_instance.main.master_user_secret[0].secret_arn
}

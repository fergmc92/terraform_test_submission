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

variable "ecs_sg_id" {
  type = string
}

variable "db_sg_id" {
  type = string
}

locals {
  db_port = 5432
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-${var.service}-db-subnets"
  subnet_ids = var.db_subnets
}

resource "aws_db_instance" "main" {
  identifier              = "${var.environment}-${var.service}-db"
  allocated_storage       = 20
  storage_type            = "gp2"
  engine                  = "postgres"
  engine_version          = "13"
  instance_class          = "db.t2.micro"
  db_name                 = "appdb"
  username                = "dbadmin"
  password                = "ChangeThisPassword123!"
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [var.db_sg_id]
  skip_final_snapshot     = true
  publicly_accessible     = false
  multi_az                = true
  backup_retention_period = 7

  tags = {
    Name = "${var.environment}-${var.service}-db"
  }
}

output "endpoint" {
  value = aws_db_instance.main.address
}

variable "aws_region" {
  description = "AWS region for the deployment"
  type        = string
  default     = "eu-west-2"
}

variable "environment" {
  description = "Environment name used in resource names and tags"
  type        = string
  default     = "test"
}

variable "service" {
  description = "Service name used in resource names and tags"
  type        = string
  default     = "nginx"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Two availability zones used by the baseline architecture"
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b"]

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "Exactly two availability zones are required for this iteration."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDRs for the two public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "app_subnet_cidrs" {
  description = "CIDRs for the two private application subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "db_subnet_cidrs" {
  description = "CIDRs for the two private database subnets"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "app_port" {
  description = "Port exposed by the application container"
  type        = number
  default     = 80
}

variable "db_port" {
  description = "Database listener port"
  type        = number
  default     = 5432
}

variable "container_image" {
  description = "Immutable application image reference"
  type        = string
  default     = "nginx:1.27.1"
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 2
}

variable "task_cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate task memory in MiB"
  type        = number
  default     = 512
}

variable "log_retention_days" {
  description = "CloudWatch log retention period"
  type        = number
  default     = 30
}

variable "db_name" {
  description = "Application database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "RDS master username; the password is managed by RDS and Secrets Manager"
  type        = string
  default     = "dbadmin"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "backup_retention_days" {
  description = "Number of days RDS retains automated backups"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Prevent accidental deletion of the database"
  type        = bool
  default     = false
}

variable "enable_https" {
  description = "Enable HTTPS and redirect HTTP to HTTPS"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = !var.enable_https || var.certificate_arn != null
    error_message = "certificate_arn must be set when enable_https is true."
  }
}

variable "alb_log_bucket_name" {
  description = "Optional S3 bucket name for ALB access logs"
  type        = string
  default     = null
  nullable    = true
}

variable "alb_deletion_protection" {
  description = "Prevent accidental deletion of the application load balancer"
  type        = bool
  default     = false
}

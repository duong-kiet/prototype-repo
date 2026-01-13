# ===========================
# Project Variables
# ===========================

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "security-pipeline"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

# ===========================
# VPC Variables
# ===========================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

# ===========================
# ECS Variables
# ===========================

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 5000
}

variable "container_cpu" {
  description = "CPU units for the container"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "Memory for the container in MB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of containers"
  type        = number
  default     = 1
}

# ===========================
# Tags
# ===========================

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project   = "security-pipeline"
    ManagedBy = "terraform"
  }
}


# ===========================
# Terraform Configuration
# ===========================

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment to use S3 backend for state management
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "security-pipeline/terraform.tfstate"
  #   region         = "ap-southeast-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

# ===========================
# AWS Provider
# ===========================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(var.tags, {
      Environment = var.environment
    })
  }
}

# ===========================
# Data Sources
# ===========================

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}


terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
  # Apply default tags to all resources
  default_tags {
    tags = {
      Environment = "vm-series-demo"
      ManagedBy   = "terraform"
      Project     = "swfw"
      # DeploymentId removed - will be added to individual resources
    }
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# =============================================================================
# TERRAFORM CONFIGURATION - PHASE 1 SIMPLIFIED
# =============================================================================

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# =============================================================================
# AWS PROVIDER CONFIGURATION  
# =============================================================================

provider "aws" {
  region = var.region

  # Apply default tags to all resources
  default_tags {
    tags = {
      Environment  = "vm-series-demo"
      ManagedBy    = "terraform"
      Project      = "swfw"
      DeploymentId = random_string.deployment.result
    }
  }
}

# =============================================================================
# AWS DATA SOURCES
# =============================================================================

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}
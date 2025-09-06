# =============================================================================
# ROUTE TABLE ASSOCIATION MODULE
# =============================================================================
# This module creates route table associations for multiple subnets
# to a single route table in a simplified and reusable way.

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# =============================================================================
# ROUTE TABLE ASSOCIATIONS
# =============================================================================

resource "aws_route_table_association" "main" {
  count = length(var.subnet_ids)

  subnet_id      = var.subnet_ids[count.index]
  route_table_id = var.route_table_id

  # Add lifecycle rule to prevent accidental deletion
  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# DATA SOURCES FOR VALIDATION
# =============================================================================

data "aws_route_table" "main" {
  route_table_id = var.route_table_id
}

data "aws_subnet" "subnets" {
  count = length(var.subnet_ids)
  id    = var.subnet_ids[count.index]
}
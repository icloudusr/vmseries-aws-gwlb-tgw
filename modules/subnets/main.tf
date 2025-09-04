# =============================================================================
# SUBNETS MODULE
# =============================================================================
# This module creates multiple subnets in a VPC with flexible configuration
# and comprehensive tagging support.

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
# DATA SOURCES FOR VALIDATION
# =============================================================================

data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_availability_zones" "available" {
  state = "available"
}

# =============================================================================
# LOCALS FOR SUBNET VALIDATION AND PROCESSING
# =============================================================================

locals {
  # Validate that all AZs are valid
  valid_azs = toset(data.aws_availability_zones.available.names)
  
  # Process subnets with validation
  processed_subnets = {
    for name, config in var.subnets : name => {
      az   = config.az
      cidr = config.cidr
      
      # Optional configurations with defaults
      map_public_ip_on_launch                 = lookup(config, "map_public_ip_on_launch", false)
      assign_ipv6_address_on_creation        = lookup(config, "assign_ipv6_address_on_creation", false)
      enable_dns64                           = lookup(config, "enable_dns64", false)
      enable_resource_name_dns_a_record_on_launch    = lookup(config, "enable_resource_name_dns_a_record_on_launch", false)
      enable_resource_name_dns_aaaa_record_on_launch = lookup(config, "enable_resource_name_dns_aaaa_record_on_launch", false)
      ipv6_native                            = lookup(config, "ipv6_native", false)
      
      # Custom tags from subnet config
      tags = lookup(config, "tags", {})
    }
  }
}

# =============================================================================
# SUBNET RESOURCES
# =============================================================================

resource "aws_subnet" "main" {
  for_each = local.processed_subnets

  vpc_id            = var.vpc_id
  availability_zone = each.value.az
  cidr_block        = each.value.cidr

  # Optional networking configurations
  map_public_ip_on_launch                 = each.value.map_public_ip_on_launch
  assign_ipv6_address_on_creation        = each.value.assign_ipv6_address_on_creation
  enable_dns64                           = each.value.enable_dns64
  enable_resource_name_dns_a_record_on_launch    = each.value.enable_resource_name_dns_a_record_on_launch
  enable_resource_name_dns_aaaa_record_on_launch = each.value.enable_resource_name_dns_aaaa_record_on_launch
  ipv6_native                            = each.value.ipv6_native

  # Comprehensive tagging
  tags = merge(
    {
      Name = "${var.subnet_name_prefix}${each.key}"
      Type = "Subnet"
      VPC  = data.aws_vpc.main.id
      AZ   = each.value.az
      CIDR = each.value.cidr
    },
    var.common_tags,
    each.value.tags
  )

  # Lifecycle management
  lifecycle {
    create_before_destroy = true
  }
}
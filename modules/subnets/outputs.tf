# =============================================================================
# SUBNETS MODULE - OUTPUTS
# =============================================================================

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value = {
    for name, subnet in aws_subnet.main : name => subnet.id
  }
}

output "subnet_arns" {
  description = "Map of subnet names to their ARNs"
  value = {
    for name, subnet in aws_subnet.main : name => subnet.arn
  }
}

output "subnet_cidr_blocks" {
  description = "Map of subnet names to their CIDR blocks"
  value = {
    for name, subnet in aws_subnet.main : name => subnet.cidr_block
  }
}

output "subnet_availability_zones" {
  description = "Map of subnet names to their availability zones"
  value = {
    for name, subnet in aws_subnet.main : name => subnet.availability_zone
  }
}

# =============================================================================
# DETAILED SUBNET INFORMATION
# =============================================================================

output "subnet_details" {
  description = "Comprehensive information about all created subnets"
  value = {
    for name, subnet in aws_subnet.main : name => {
      id                = subnet.id
      arn               = subnet.arn
      cidr_block        = subnet.cidr_block
      availability_zone = subnet.availability_zone
      vpc_id            = subnet.vpc_id

      # Networking configurations
      map_public_ip_on_launch                        = subnet.map_public_ip_on_launch
      assign_ipv6_address_on_creation                = subnet.assign_ipv6_address_on_creation
      enable_dns64                                   = subnet.enable_dns64
      enable_resource_name_dns_a_record_on_launch    = subnet.enable_resource_name_dns_a_record_on_launch
      enable_resource_name_dns_aaaa_record_on_launch = subnet.enable_resource_name_dns_aaaa_record_on_launch
      ipv6_native                                    = subnet.ipv6_native

      # IPv6 information (if applicable)
      ipv6_cidr_block                = subnet.ipv6_cidr_block
      ipv6_cidr_block_association_id = subnet.ipv6_cidr_block_association_id

      # Metadata
      owner_id = subnet.owner_id
      tags     = subnet.tags
      tags_all = subnet.tags_all
    }
  }
}

# =============================================================================
# SUMMARY OUTPUTS
# =============================================================================

output "subnet_count" {
  description = "Total number of subnets created"
  value       = length(aws_subnet.main)
}

output "availability_zones_used" {
  description = "List of availability zones where subnets were created"
  value       = distinct([for subnet in aws_subnet.main : subnet.availability_zone])
}

output "total_ip_addresses" {
  description = "Total number of IP addresses across all subnets"
  value = sum([
    for subnet in aws_subnet.main : pow(2, 32 - tonumber(split("/", subnet.cidr_block)[1])) - 5
  ])
}

# =============================================================================
# ORGANIZED OUTPUTS BY TYPE
# =============================================================================

output "subnets_by_az" {
  description = "Subnets organized by availability zone"
  value = {
    for az in distinct([for subnet in aws_subnet.main : subnet.availability_zone]) : az => {
      for name, subnet in aws_subnet.main : name => {
        id         = subnet.id
        cidr_block = subnet.cidr_block
      } if subnet.availability_zone == az
    }
  }
}

output "public_subnets" {
  description = "List of subnet IDs that have public IP assignment enabled"
  value = [
    for subnet in aws_subnet.main : subnet.id
    if subnet.map_public_ip_on_launch
  ]
}

output "private_subnets" {
  description = "List of subnet IDs that do not have public IP assignment enabled"
  value = [
    for subnet in aws_subnet.main : subnet.id
    if !subnet.map_public_ip_on_launch
  ]
}

# =============================================================================
# LEGACY OUTPUT (For Backward Compatibility)
# =============================================================================

output "subnet_id" {
  description = "[DEPRECATED] Use subnet_ids instead. List of all subnet IDs"
  value       = values(aws_subnet.main)[*].id
}
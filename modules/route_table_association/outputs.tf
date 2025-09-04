# =============================================================================
# ROUTE TABLE ASSOCIATION MODULE - OUTPUTS
# =============================================================================

output "association_ids" {
  description = "List of route table association IDs"
  value       = aws_route_table_association.main[*].id
}

output "route_table_id" {
  description = "ID of the route table used for associations"
  value       = var.route_table_id
}

output "subnet_ids" {
  description = "List of subnet IDs that were associated with the route table"
  value       = var.subnet_ids
}

output "association_count" {
  description = "Number of route table associations created"
  value       = length(aws_route_table_association.main)
}

output "route_table_info" {
  description = "Information about the route table used"
  value = {
    id     = data.aws_route_table.main.id
    vpc_id = data.aws_route_table.main.vpc_id
    tags   = data.aws_route_table.main.tags
  }
}

output "subnet_info" {
  description = "Information about the associated subnets"
  value = [
    for subnet in data.aws_subnet.subnets : {
      id                = subnet.id
      vpc_id            = subnet.vpc_id
      availability_zone = subnet.availability_zone
      cidr_block        = subnet.cidr_block
    }
  ]
}
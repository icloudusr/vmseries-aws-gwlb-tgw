# =============================================================================
# ROUTE TABLE ASSOCIATION MODULE - VARIABLES
# =============================================================================

variable "route_table_id" {
  description = "ID of the route table to associate subnets with"
  type        = string
  
  validation {
    condition     = length(var.route_table_id) > 0
    error_message = "Route table ID cannot be empty."
  }
  
  validation {
    condition     = can(regex("^rtb-", var.route_table_id))
    error_message = "Route table ID must be a valid AWS route table ID (starts with 'rtb-')."
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs to associate with the route table"
  type        = list(string)
  
  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "At least one subnet ID must be provided."
  }
  
  validation {
    condition = alltrue([
      for subnet_id in var.subnet_ids : can(regex("^subnet-", subnet_id))
    ])
    error_message = "All subnet IDs must be valid AWS subnet IDs (start with 'subnet-')."
  }
  
  validation {
    condition     = length(var.subnet_ids) == length(distinct(var.subnet_ids))
    error_message = "Subnet IDs must be unique (no duplicates allowed)."
  }
}
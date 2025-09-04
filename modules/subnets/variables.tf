# =============================================================================
# SUBNETS MODULE - VARIABLES
# =============================================================================

variable "vpc_id" {
  description = "ID of the VPC where subnets will be created"
  type        = string
  
  validation {
    condition     = length(var.vpc_id) > 0
    error_message = "VPC ID cannot be empty."
  }
  
  validation {
    condition     = can(regex("^vpc-", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC ID (starts with 'vpc-')."
  }
}

variable "subnet_name_prefix" {
  description = "Prefix to add to subnet names for consistent naming"
  type        = string
  default     = ""
  
  validation {
    condition     = length(var.subnet_name_prefix) <= 50
    error_message = "Subnet name prefix must be 50 characters or less."
  }
}

variable "subnets" {
  description = <<-EOT
    Map of subnet configurations. Each subnet must have:
    - az: Availability zone for the subnet
    - cidr: CIDR block for the subnet
    
    Optional configurations:
    - map_public_ip_on_launch: Auto-assign public IPs (default: false)
    - assign_ipv6_address_on_creation: Auto-assign IPv6 addresses (default: false)
    - enable_dns64: Enable DNS64 (default: false)
    - enable_resource_name_dns_a_record_on_launch: Enable DNS A records (default: false)
    - enable_resource_name_dns_aaaa_record_on_launch: Enable DNS AAAA records (default: false)
    - ipv6_native: IPv6-only subnet (default: false)
    - tags: Additional tags for the subnet (default: {})
  EOT
  
  type = map(object({
    az   = string
    cidr = string
    
    # Optional networking configurations
    map_public_ip_on_launch                 = optional(bool, false)
    assign_ipv6_address_on_creation        = optional(bool, false)
    enable_dns64                           = optional(bool, false)
    enable_resource_name_dns_a_record_on_launch    = optional(bool, false)
    enable_resource_name_dns_aaaa_record_on_launch = optional(bool, false)
    ipv6_native                            = optional(bool, false)
    
    # Additional tags
    tags = optional(map(string), {})
  }))
  
  validation {
    condition     = length(var.subnets) > 0
    error_message = "At least one subnet configuration must be provided."
  }
  
  # Validate CIDR blocks
  validation {
    condition = alltrue([
      for subnet_config in var.subnets : can(cidrhost(subnet_config.cidr, 0))
    ])
    error_message = "All subnet CIDR blocks must be valid."
  }
  
  # Validate availability zones are not empty
  validation {
    condition = alltrue([
      for subnet_config in var.subnets : length(subnet_config.az) > 0
    ])
    error_message = "All availability zones must be specified."
  }
  
  # Validate unique subnet names
  validation {
    condition     = length(keys(var.subnets)) == length(distinct(keys(var.subnets)))
    error_message = "All subnet names must be unique."
  }
}

variable "common_tags" {
  description = "Common tags to apply to all subnets"
  type        = map(string)
  default     = {}
  
  validation {
    condition     = can(var.common_tags)
    error_message = "Common tags must be a valid map of strings."
  }
}

# =============================================================================
# DEPRECATED VARIABLES (For Backward Compatibility)
# =============================================================================

variable "cidr_block" {
  description = "[DEPRECATED] This variable is no longer used. Define CIDR blocks in the subnets variable."
  type        = string
  default     = null
}
  # =============================================================================
# VM-SERIES MODULE - VARIABLES (PHASE 1 - BACKWARD COMPATIBLE)
# =============================================================================

# =============================================================================
# REQUIRED VARIABLES
# =============================================================================

variable "vpc_id" {
  description = "ID of the VPC where VM-Series will be deployed"
  type        = string
}

variable "name" {
  description = "Name prefix for VM-Series resources"
  type        = string
  default     = "vmseries"
}

variable "size" {
  description = "EC2 instance type for VM-Series firewall"
  type        = string
}

variable "license" {
  description = "VM-Series license type"
  type        = string
}

variable "panos" {
  description = "PAN-OS version for VM-Series (e.g., 11.1.6)"
  type        = string
}

variable "key_name" {
  description = "Name of the EC2 Key Pair for VM access"
  type        = string
}

# =============================================================================
# NETWORK INTERFACE VARIABLES
# =============================================================================

variable "eni0_subnet" {
  description = "Subnet ID for ENI0 (Trust/Data interface)"
  type        = string
}

variable "eni1_subnet" {
  description = "Subnet ID for ENI1 (Management interface)"
  type        = string
}

variable "eni2_subnet" {
  description = "Subnet ID for ENI2 (Untrust/Data interface) - Optional"
  type        = string
  default     = null
}

# ✅ NEW: Boolean control for ENI2 creation
variable "create_eni2" {
  description = "Whether to create ENI2 interfaces"
  type        = bool
  default     = true
}

# =============================================================================
# PUBLIC IP CONFIGURATION
# =============================================================================

variable "eni0_public_ip" {
  description = "Assign public IP to ENI0 (Trust interface)"
  type        = bool
  default     = false
}

variable "eni1_public_ip" {
  description = "Assign public IP to ENI1 (Management interface)"
  type        = bool
  default     = true
}

variable "eni2_public_ip" {
  description = "Assign public IP to ENI2 (Untrust interface)"
  type        = bool
  default     = false
}

# =============================================================================
# SECURITY CONFIGURATION - WITH BACKWARD COMPATIBILITY
# =============================================================================

variable "mgmt_sg_cidrs" {
  description = "List of CIDR blocks allowed to access management interface"
  type        = list(string)
  default     = null
}

# ✅ BACKWARD COMPATIBILITY - Support old variable name
variable "eni0_sg_prefix" {
  description = "DEPRECATED: Use mgmt_sg_cidrs instead. CIDR blocks for management access"
  type        = list(string)
  default     = null
}

# =============================================================================
# INSTANCE CONFIGURATION
# =============================================================================

variable "vm_count" {
  description = "Number of VM-Series instances to deploy"
  type        = number
  default     = 1

  validation {
    condition     = var.vm_count > 0 && var.vm_count <= 10
    error_message = "vm_count must be at between 0 and 10"
  }
}

variable "instance_profile" {
  description = "IAM instance profile name for VM-Series (for S3 bootstrap access)"
  type        = string
  default     = null
}

variable "user_data" {
  description = "User data script for VM-Series initialization (typically bootstrap parameters)"
  type        = string
  default     = ""
}

variable "enable_termination_protection" {
  description = "Enable termination protection for VM-Series instances"
  type        = bool
  default     = false
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring for VM-Series instances"
  type        = bool
  default     = false
}

# =============================================================================
# STORAGE CONFIGURATION
# =============================================================================

variable "root_volume_type" {
  description = "EBS volume type for root volume"
  type        = string
  default     = "gp3"
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 60
}

variable "root_volume_encrypted" {
  description = "Enable encryption for root volume"
  type        = bool
  default     = true
}

# =============================================================================
# TAGGING CONFIGURATION
# =============================================================================

variable "environment" {
  description = "Environment name for resource tagging"
  type        = string
  default     = "demo"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "vm-series"
}

variable "common_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# =============================================================================
# LICENSE TYPE MAP (Internal Configuration)
# =============================================================================

variable "license_type_map" {
  description = "Mapping of license types to AWS Marketplace product codes"
  type        = map(string)
  default = {
    "byol"    = "6njl1pau431dv1qxipg63mvah"
    "bundle1" = "e9yfvyj3uag5uo5j2hjikv74n"  
    "bundle2" = "hd44w1chf26uv4p52cdynb2o"
  }
}

# =============================================================================
# LEGACY/DEPRECATED VARIABLES (For Backward Compatibility)
# =============================================================================

variable "dependencies" {
  description = "DEPRECATED: This variable is no longer used"
  type        = list(string)
  default     = []
}
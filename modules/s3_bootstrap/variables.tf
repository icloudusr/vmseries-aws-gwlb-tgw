# =============================================================================
# S3 BOOTSTRAP MODULE - VARIABLES (PHASE 1 - BACKWARD COMPATIBLE)
# =============================================================================

variable "bucket_name" {
  description = "Name of the S3 bucket for VM-Series bootstrap files"
  type        = string
}

variable "file_location" {
  description = "Local directory path where bootstrap files are located"
  type        = string
}

variable "project_name" {
  description = "Name of the project for resource tagging"
  type        = string
  default     = "vm-series-bootstrap"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "demo"
}

# =============================================================================
# NEW BOOTSTRAP FILE VARIABLES (Using sets)
# =============================================================================

variable "config_files" {
  description = "Set of configuration files to upload to config/ directory"
  type        = set(string)
  default     = []
}

variable "content_files" {
  description = "Set of content files to upload to content/ directory"
  type        = set(string)
  default     = []
}

variable "license_files" {
  description = "Set of license files to upload to license/ directory"
  type        = set(string)
  default     = []
}

variable "software_files" {
  description = "Set of software files to upload to software/ directory"
  type        = set(string)
  default     = []
}

variable "other_files" {
  description = "Set of other files to upload (with custom paths)"
  type        = set(string)
  default     = []
}

# =============================================================================
# S3 BUCKET CONFIGURATION VARIABLES
# =============================================================================

variable "force_destroy" {
  description = "Allow bucket to be destroyed even if it contains objects"
  type        = bool
  default     = true
}

variable "enable_lifecycle" {
  description = "Enable lifecycle management for the S3 bucket"
  type        = bool
  default     = false  # Simplified for Phase 1
}

variable "versioning_enabled" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

# =============================================================================
# IAM CONFIGURATION VARIABLES
# =============================================================================

variable "create_instance_profile" {
  description = "Create IAM instance profile for VM-Series bootstrap access"
  type        = bool
  default     = true
}

variable "enable_cloudwatch" {
  description = "Enable CloudWatch monitoring capabilities"
  type        = bool
  default     = false  # Simplified for Phase 1
}

variable "enable_ssm" {
  description = "Enable AWS Systems Manager capabilities"
  type        = bool
  default     = false  # Simplified for Phase 1
}

# =============================================================================
# LEGACY COMPATIBILITY VARIABLES (OLD FORMAT - BACKWARD COMPATIBLE)
# =============================================================================

variable "config" {
  description = "List of config files (legacy format - use config_files instead)"
  type        = list(string)
  default     = []
}

variable "content" {
  description = "List of content files (legacy format - use content_files instead)"
  type        = list(string)
  default     = []
}

variable "license" {
  description = "List of license files (legacy format - use license_files instead)"
  type        = list(string)
  default     = []
}

variable "software" {
  description = "List of software files (legacy format - use software_files instead)"
  type        = list(string)
  default     = []
}

variable "other" {
  description = "List of other files (legacy format - use other_files instead)"
  type        = list(string)
  default     = []
}
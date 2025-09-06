# =============================================================================
# S3 BOOTSTRAP BUCKET FOR VM-SERIES
# =============================================================================

# Random string for unique naming (moved from module to main)
resource "random_string" "deployment" {
  length  = 8
  lower   = true
  upper   = false
  numeric = true
  special = false
}

module "vmseries_bootstrap" {
  source = "./modules/s3_bootstrap/"

  file_location           = "bootstrap_files/"
  bucket_name             = "swfw-bootstrap-${random_string.deployment.result}"
  project_name            = "swfw"
  environment             = "demo"
  
  # ✅ FIXED: Use new variable names
  config_files            = ["bootstrap.xml", "init-cfg.txt"]
  license_files           = ["authcodes"]
  content_files           = []
  software_files          = []
  other_files             = []
  
  create_instance_profile = true
  enable_cloudwatch       = true
}

# =============================================================================
# VM-SERIES FIREWALLS - AZ1 
# =============================================================================

module "fw_az1" {
  source = "./modules/vmseries/"
  
  # Basic configuration
  name     = "${var.fw_prefix}-az1"
  vpc_id   = aws_vpc.inspection.id
  vm_count = var.fw_count_az1
  size     = var.fw_size
  key_name = var.key_name
  panos    = var.fw_panos
  license  = var.fw_license
  
  # ✅ FIXED: Use correct variable name
  mgmt_sg_cidrs = var.fw_mgmt_src_cidrs
  
  # Network interface configuration - AZ1 SUBNETS
  eni0_subnet = module.vmseries_subnets.subnet_ids["trust-az1"]
  eni1_subnet = module.vmseries_subnets.subnet_ids["mgmt-az1"]
  eni2_subnet = module.vmseries_subnets.subnet_ids["untrust-az1"]
  
  create_eni2 = true

  # Public IP configuration
  eni0_public_ip = false
  eni1_public_ip = true
  eni2_public_ip = true

  # Bootstrap configuration
  user_data        = "vmseries-bootstrap-aws-s3bucket=${module.vmseries_bootstrap.bucket_name}\nmgmt-interface-swap=enable"
  instance_profile = module.vmseries_bootstrap.instance_profile
  
  # Project configuration
  project_name = "swfw"
  environment  = "demo"

  depends_on = [
    module.vmseries_bootstrap,
    aws_vpc_endpoint.s3
  ]
}

# =============================================================================
# VM-SERIES FIREWALLS - AZ2 (BUG FIXED)
# =============================================================================

module "fw_az2" {
  source = "./modules/vmseries/"
  
  # Basic configuration
  name     = "${var.fw_prefix}-az2"
  vpc_id   = aws_vpc.inspection.id
  vm_count = var.fw_count_az2
  size     = var.fw_size
  key_name = var.key_name
  panos    = var.fw_panos
  license  = var.fw_license
  
  # ✅ FIXED: Use correct variable name
  mgmt_sg_cidrs = var.fw_mgmt_src_cidrs
  
  # ✅ CRITICAL FIX: Use AZ2 subnets for AZ2 firewalls
  eni0_subnet = module.vmseries_subnets.subnet_ids["trust-az2"]
  eni1_subnet = module.vmseries_subnets.subnet_ids["mgmt-az2"]
  eni2_subnet = module.vmseries_subnets.subnet_ids["untrust-az2"]
  
  create_eni2 = true

  # Public IP configuration
  eni0_public_ip = false
  eni1_public_ip = true
  eni2_public_ip = true
  
  # Bootstrap configuration
  user_data        = "vmseries-bootstrap-aws-s3bucket=${module.vmseries_bootstrap.bucket_name}\nmgmt-interface-swap=enable"
  instance_profile = module.vmseries_bootstrap.instance_profile
  
  # Project configuration
  project_name = "swfw"
  environment  = "demo"

  depends_on = [
    module.vmseries_bootstrap,
    aws_vpc_endpoint.s3
  ]
}

# =============================================================================
# OUTPUTS - ENHANCED FORMAT
# =============================================================================

output "firewall_management_urls" {
  description = "VM-Series firewall management interface URLs"
  value = {
    fw_az1 = length(module.fw_az1.management_urls) > 0 ? module.fw_az1.management_urls[0] : "Not available"
    fw_az2 = length(module.fw_az2.management_urls) > 0 ? module.fw_az2.management_urls[0] : "Not available"
  }
}

output "firewall_trust_ips" {
  description = "VM-Series firewall trust interface private IPs"
  value = {
    fw_az1 = module.fw_az1.eni0_private_ip
    fw_az2 = module.fw_az2.eni0_private_ip
  }
}

output "bootstrap_bucket_name" {
  description = "S3 bootstrap bucket name"
  value       = module.vmseries_bootstrap.bucket_name
}
# -----------------------------------------------------------------------------------------------
# Create S3 bucket to bootstrap VM-Series

module "vmseries_bootstrap" {
  source = "./modules/s3_bootstrap/"

  file_location           = "bootstrap_files/"
  bucket_name             = "vmseries-bootstrap-${random_string.main.result}"
  config                  = ["bootstrap.xml", "init-cfg.txt"]
  license                 = ["authcodes"]
  content                 = []
  software                = []
  other                   = []
  create_instance_profile = true
}

# -----------------------------------------------------------------------------------------------
# Create VM-Series in AZ1 & AZ2

module "fw_az1" {
  source         = "./modules/vmseries/"
  name           = "${var.fw_prefix}-az1"
  vpc_id         = aws_vpc.security.id
  vm_count       = var.fw_count_az1
  size           = var.fw_size
  key_name       = var.key_name
  panos          = var.fw_panos
  license        = var.fw_license
  eni0_sg_prefix = var.fw_mgmt_src_cidrs
  eni0_subnet    = module.vmseries_subnets.subnet_ids["trust-az1"]
  eni1_subnet    = module.vmseries_subnets.subnet_ids["mgmt-az1"]
  eni2_subnet    = module.vmseries_subnets.subnet_ids["untrust-az1"]
  eni0_public_ip = false
  eni1_public_ip = true
  eni2_public_ip = true
  user_data      = "vmseries-bootstrap-aws-s3bucket=${module.vmseries_bootstrap.bucket_name}\nmgmt-interface-swap=enable"
  instance_profile = module.vmseries_bootstrap.instance_profile

  depends_on = [
    module.vmseries_bootstrap,
    aws_vpc_endpoint.s3
  ]
}

module "fw_az2" {
  source         = "./modules/vmseries/"
  name           = "${var.fw_prefix}-az2"
  vpc_id         = aws_vpc.security.id
  vm_count       = var.fw_count_az2
  size           = var.fw_size
  key_name       = var.key_name
  panos          = var.fw_panos
  license        = var.fw_license
  eni0_sg_prefix = var.fw_mgmt_src_cidrs
  eni0_subnet    = module.vmseries_subnets.subnet_ids["trust-az1"]
  eni1_subnet    = module.vmseries_subnets.subnet_ids["mgmt-az1"]
  eni2_subnet    = module.vmseries_subnets.subnet_ids["untrust-az1"]
  eni0_public_ip = false
  eni1_public_ip = true
  eni2_public_ip = true
  user_data      = "vmseries-bootstrap-aws-s3bucket=${module.vmseries_bootstrap.bucket_name}\nmgmt-interface-swap=enable"
  instance_profile = module.vmseries_bootstrap.instance_profile

  depends_on = [
    module.vmseries_bootstrap,
    aws_vpc_endpoint.s3
  ]
}

output "FW1_MGMT" {
  value = "https://${module.fw_az1.eni1_public_ip[0]}"
}

output "FW2_MGMT" {
  value = "https://${module.fw_az2.eni1_public_ip[0]}"
}

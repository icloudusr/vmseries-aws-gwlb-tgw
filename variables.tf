variable "region" {}

variable "key_name" {
  description = "Name of an existing EC2 Key Pair"
}

variable "your_public_ip" {
  description = "Enter your public IP address.  This IP is used to create a host route on Spoke2 for SSH jump access"
}
variable "fw_license" {
  description = "Firewall license.  Must be byol, bundle1, or bundle2"
}

variable "fw_prefix" {}
variable "fw_vpc_cidr" {}
variable "fw_count_az1" {}
variable "fw_count_az2" {}
variable "fw_size" {}
variable "fw_panos" {}
variable "fw_mgmt_src_cidrs" {
  type        = list(string)
}

variable "fw_cidr_mgmt_az1" {}
variable "fw_cidr_mgmt_az2" {}
variable "fw_cidr_trust_az1" {}
variable "fw_cidr_trust_az2" {}
variable "fw_cidr_untrust_az1" {}
variable "fw_cidr_untrust_az2" {}
variable "fw_cidr_gwlbe_az1" {}
variable "fw_cidr_gwlbe_az2" {}
variable "fw_cidr_tgw_az1" {}
variable "fw_cidr_tgw_az2" {}

variable "spoke1_prefix" {}
variable "spoke1_vpc_cidr" {}
variable "spoke1_cidr_vm_az1" {}
variable "spoke1_cidr_vm_az2" {}
variable "spoke1_cidr_alb_az1" {}
variable "spoke1_cidr_alb_az2" {}
variable "spoke1_cidr_gwlbe_az1" {}
variable "spoke1_cidr_gwlbe_az2" {}
variable "spoke1_vm1_ip" {}
variable "spoke1_vm2_ip" {}

variable "spoke2_prefix" {}
variable "spoke2_vpc_cidr" {}
variable "spoke2_subnet_cidr" {}
variable "spoke2_vm1_ip" {}
variable "spoke_size" {}

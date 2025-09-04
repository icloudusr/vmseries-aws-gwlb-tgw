variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-1"
}

variable "fw_prefix" {
  description = "Prefix for firewall resources"
  type        = string
  default     = "swfw"
}

variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
  default     = "gwlb-us"
}

variable "fw_mgmt_src_cidrs" {
  description = "CIDR blocks for firewall management access"
  type        = list(string)
  default     = ["98.97.0.0/16"]
}

variable "panos" {
  description = "PAN-OS version"
  type        = string
  default     = "11.1.6"
}

variable "fw_license" { 
  description = "FW License Type"
  type        = string
  default = "byol" 
}

variable "fw_panos" {
  description = "PANOS Version"
  type        = string 
  default = "11.1.6" 
}

variable "fw_size" {
  description = "Instance Size"
  type        = string 
  default = "c6in.xlarge" 
}

variable "fw_count_az1" {
  description = "FW Count for AZ1"
  type        = string
  default = 1 
}

variable "fw_count_az2" {
  description = "FW Count for AZ2"
  type        = string 
  default = 1 
}

variable "your_public_ip" {
  description = "my publiocv IP range"
  type        = string 
  default = "98.97.0.0/16" 
}

variable "spoke_size" {
  description = "spoke instance size"
  type        = string 
  default = "t3.micro" 
}

variable "fw_instance_type" {
  description = "VM-Series instance type"
  type        = string
  default     = "c6in.xlarge"
}

# Inspection VPC
variable "inspection_cidr" {
  description = "CIDR block for inspection VPC"
  type        = string
  default     = "10.210.0.0/16"
}

variable "inspection_cidr_mgmt_az1" {
  description = "CIDR for inspection VPC management subnet AZ1"
  type        = string
  default     = "10.210.0.0/28"
}

variable "inspection_cidr_mgmt_az2" {
  description = "CIDR for inspection VPC management subnet AZ2"
  type        = string
  default     = "10.210.0.16/28"
}

variable "inspection_cidr_public_az1" {
  description = "CIDR for inspection VPC public subnet AZ1"
  type        = string
  default     = "10.210.1.0/28"
}

variable "inspection_cidr_public_az2" {
  description = "CIDR for inspection VPC public subnet AZ2"
  type        = string
  default     = "10.210.1.16/28"
}

variable "inspection_cidr_private_az1" {
  description = "CIDR for inspection VPC private subnet AZ1"
  type        = string
  default     = "10.210.2.0/28"
}

variable "inspection_cidr_private_az2" {
  description = "CIDR for inspection VPC private subnet AZ2"
  type        = string
  default     = "10.210.2.16/28"
}

variable "inspection_cidr_gwlbe_az1" {
  description = "CIDR for inspection VPC GWLB endpoint subnet AZ1"
  type        = string
  default     = "10.210.3.0/28"
}

variable "inspection_cidr_gwlbe_az2" {
  description = "CIDR for inspection VPC GWLB endpoint subnet AZ2"
  type        = string
  default     = "10.210.3.16/28"
}

# SPK1 VPC
variable "spk1_cidr" {
  description = "CIDR block for spk1 VPC"
  type        = string
  default     = "10.211.0.0/16"
}

variable "spk1_cidr_vm_az1" {
  description = "CIDR for spk1 VPC VM subnet AZ1"
  type        = string
  default     = "10.211.1.0/24"
}

variable "spk1_cidr_vm_az2" {
  description = "CIDR for spk1 VPC VM subnet AZ2"
  type        = string
  default     = "10.211.2.0/24"
}

variable "spk1_cidr_gwlbe_az1" {
  description = "CIDR for spk1 VPC GWLB endpoint subnet AZ1"
  type        = string
  default     = "10.211.3.0/28"
}

variable "spk1_cidr_gwlbe_az2" {
  description = "CIDR for spk1 VPC GWLB endpoint subnet AZ2"
  type        = string
  default     = "10.211.3.16/28"
}

# SPK2 VPC
variable "spk2_cidr" {
  description = "CIDR block for spk2 VPC"
  type        = string
  default     = "10.212.0.0/16"
}

variable "spk2_cidr_vm_az1" {
  description = "CIDR for spk2 VPC VM subnet AZ1"
  type        = string
  default     = "10.212.1.0/24"
}

variable "spk2_cidr_vm_az2" {
  description = "CIDR for spk2 VPC VM subnet AZ2"
  type        = string
  default     = "10.212.2.0/24"
}

variable "spk2_cidr_gwlbe_az1" {
  description = "CIDR for spk2 VPC GWLB endpoint subnet AZ1"
  type        = string
  default     = "10.212.3.0/28"
}

variable "spk2_cidr_gwlbe_az2" {
  description = "CIDR for spk2 VPC GWLB endpoint subnet AZ2"
  type        = string
  default     = "10.212.3.16/28"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    project = "swfw"
    Environment = "demo"
    ManagedBy = "terraform"
  }
}
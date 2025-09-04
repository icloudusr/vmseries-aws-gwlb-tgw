# =============================================================================
# GENERAL CONFIGURATION
# =============================================================================

region         = "us-east-2"
key_name       = "gwlb-us"               # EC2 Key Pair - Must exist prior to launch
your_public_ip = "98.97.0.0/16"         # Management access CIDR (broad range as requested)

# =============================================================================
# VM-SERIES FIREWALL CONFIGURATION
# =============================================================================

fw_license           = "byol"
# fw_license         = "bundle1"
# fw_license         = "bundle2"

fw_panos             = "11.1.6"          # Updated PAN-OS version
fw_prefix            = "swfw"            # Project-specific prefix
fw_count_az1         = 1
fw_count_az2         = 1
fw_size              = "c6in.xlarge"     # Updated instance type
fw_mgmt_src_cidrs    = ["98.97.0.0/16"]  # Management access from your network

# =============================================================================
# INSPECTION VPC CONFIGURATION (previously Security VPC)
# =============================================================================

fw_vpc_cidr           = "10.210.0.0/16"   # Inspection VPC CIDR
fw_cidr_mgmt_az1      = "10.210.0.0/28"
fw_cidr_mgmt_az2      = "10.210.0.16/28"
fw_cidr_trust_az1     = "10.210.1.0/28"
fw_cidr_trust_az2     = "10.210.1.16/28"
fw_cidr_untrust_az1   = "10.210.2.0/28"
fw_cidr_untrust_az2   = "10.210.2.16/28"
fw_cidr_gwlbe_az1     = "10.210.3.0/28"
fw_cidr_gwlbe_az2     = "10.210.3.16/28"
fw_cidr_tgw_az1       = "10.210.4.0/28"
fw_cidr_tgw_az2       = "10.210.4.16/28"

# =============================================================================
# SPK1 VPC CONFIGURATION (previously Spoke1)
# =============================================================================

spk1_prefix           = "spk1"
spk1_vpc_cidr         = "10.211.0.0/16"   # Spk1 VPC CIDR
spk1_cidr_vm_az1      = "10.211.0.0/28"
spk1_cidr_vm_az2      = "10.211.0.16/28"
spk1_cidr_alb_az1     = "10.211.1.0/28"
spk1_cidr_alb_az2     = "10.211.1.16/28"
spk1_cidr_gwlbe_az1   = "10.211.2.0/28"
spk1_cidr_gwlbe_az2   = "10.211.2.16/28"
spk1_vm1_ip           = "10.211.0.4"
spk1_vm2_ip           = "10.211.0.20"

# =============================================================================
# SPK2 VPC CONFIGURATION (previously Spoke2)
# =============================================================================

spk2_prefix           = "spk2"
spk2_vpc_cidr         = "10.212.0.0/16"   # Spk2 VPC CIDR
spk2_subnet_cidr      = "10.212.0.0/24"
spk2_vm1_ip           = "10.212.0.4"

# =============================================================================
# INSTANCE CONFIGURATION
# =============================================================================

spoke_size            = "t3.micro"        # Updated from t2.micro (t3 is newer generation)
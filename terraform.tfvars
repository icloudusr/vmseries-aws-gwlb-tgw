region   = "us-east-2"
key_name = "pan-lab-mharms" // EC2 Key Pair for VMs.  Must exist prior to launch.
your_public_ip = "108.76.182.46" // Used to get jump access to spoke2 VM for testing.
fw_license           = "byol"
#fw_license           = "bundle1"
#fw_license            = "bundle2"

fw_panos              = "10.2.2-h2" // Must be 10.0 or greater. 
fw_prefix             = "vmseries"
fw_count_az1          = 1
fw_count_az2          = 1
fw_size               = "m5.large"
fw_mgmt_src_cidrs     = ["0.0.0.0/0"]

fw_vpc_cidr           = "10.0.0.0/16"
fw_cidr_mgmt_az1      = "10.0.0.0/28"
fw_cidr_mgmt_az2      = "10.0.0.16/28"
fw_cidr_trust_az1     = "10.0.1.0/28"
fw_cidr_trust_az2     = "10.0.1.16/28"
fw_cidr_untrust_az1   = "10.0.2.0/28"
fw_cidr_untrust_az2   = "10.0.2.16/28"
fw_cidr_gwlbe_az1     = "10.0.3.0/28"
fw_cidr_gwlbe_az2     = "10.0.3.16/28"
fw_cidr_tgw_az1       = "10.0.4.0/28"
fw_cidr_tgw_az2       = "10.0.4.16/28"

spoke1_prefix         = "spoke1"
spoke1_vpc_cidr       = "10.1.0.0/16"
spoke1_cidr_vm_az1    = "10.1.0.0/28"
spoke1_cidr_vm_az2    = "10.1.0.16/28"
spoke1_cidr_alb_az1   = "10.1.1.0/28"
spoke1_cidr_alb_az2   = "10.1.1.16/28"
spoke1_cidr_gwlbe_az1 = "10.1.2.0/28"
spoke1_cidr_gwlbe_az2 = "10.1.2.16/28"
spoke1_vm1_ip         = "10.1.0.4"
spoke1_vm2_ip         = "10.1.0.20"

spoke2_prefix         = "spoke2"
spoke2_vpc_cidr       = "10.2.0.0/16"
spoke2_subnet_cidr    = "10.2.0.0/24"
spoke2_vm1_ip         = "10.2.0.4"
spoke_size            = "t2.micro"



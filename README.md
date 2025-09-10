VM-Series AWS Gateway Load Balancer with Transit Gateway Demo
Overview
This Terraform project deploys a comprehensive hub-and-spoke network architecture on AWS using Palo Alto Networks VM-Series firewalls behind a Gateway Load Balancer (GWLB) for centralized security inspection. The architecture demonstrates enterprise-grade network segmentation and security inspection patterns using AWS native services integrated with VM-Series next-generation firewalls.
Architecture Diagram
Show Image
The diagram shows:

All VPC interconnections with CIDR blocks (10.210.x.x, 10.211.x.x, 10.212.x.x)
VM-Series firewall placement in Inspection VPC
Gateway Load Balancer and GWLB Endpoints configuration
Transit Gateway with route tables
Traffic flow patterns (North-South and East-West)
Component relationships and network segmentation

Architecture Components
Core Infrastructure

Inspection VPC: Central security VPC hosting VM-Series firewalls (10.210.0.0/16)
Spoke1 VPC: Application VPC with web servers behind ALB (10.211.0.0/16)
Spoke2 VPC: Jump host/bastion VPC for management (10.212.0.0/16)
Transit Gateway: Central routing hub connecting all VPCs
Gateway Load Balancer: Distributes traffic to VM-Series firewalls for inspection

Security Components

VM-Series Firewalls: PAN-OS 11.1.6 running on c6in.xlarge instances
Bootstrap Configuration: Automated firewall configuration via S3
Security Policies: Pre-configured rules for east-west and north-south traffic

Prerequisites

AWS Account with appropriate permissions
Terraform >= 1.0
AWS CLI configured with credentials
EC2 Key Pair named "gwlb-us" in us-west-1 region
VM-Series License (BYOL, Bundle1, or Bundle2)

Quick Start
1. Clone the Repository
bashgit clone https://github.com/yourusername/vmseries-aws-gwlb-tgw.git
cd vmseries-aws-gwlb-tgw
2. Configure Variables
Edit terraform.tfvars to match your environment:
hclregion         = "us-west-1"
key_name       = "gwlb-us"           # Your EC2 key pair name
your_public_ip = "YOUR_IP/32"        # Your public IP for management access
fw_license     = "byol"              # or "bundle1" or "bundle2"
3. Deploy Infrastructure
bashterraform init
terraform plan
terraform apply -auto-approve
Deployment takes approximately 15-20 minutes.
Default Credentials & Security
VM-Series Firewalls

Username: admin or paloalto
Password: PaloAlt0123!
SSH Key: Uses the EC2 key pair specified in terraform.tfvars


Note: This is a demo environment. Change these credentials immediately for production use.

Generating Secure Password Hash (phash) for Bootstrap
For production deployments, you should replace the default password hash in the bootstrap.xml file. Here's how to generate a secure password hash:
Method 1: Using OpenSSL (Linux/Mac)
Generate a password hash using OpenSSL:
bash# For MD5 hash (older PAN-OS versions)
openssl passwd -1 "YourSecurePassword"

# For SHA-256 hash (recommended for newer PAN-OS versions)
openssl passwd -5 "YourSecurePassword"

# For SHA-512 hash (most secure)
openssl passwd -6 "YourSecurePassword"
Method 2: Using Python
pythonimport crypt
import getpass

password = getpass.getpass("Enter password: ")
# Generate SHA-512 hash (recommended)
phash = crypt.crypt(password, crypt.mksalt(crypt.METHOD_SHA512))
print(f"Password hash: {phash}")
Updating bootstrap.xml with the New Password Hash

Open bootstrap_files/bootstrap.xml
Locate the user configuration section:
xml<users>
  <entry name="admin">
    <phash>$5$rounds=...</phash>
  </entry>
</users>

Replace the existing phash value with your generated hash
Save the file and update your S3 bootstrap bucket:
bashaws s3 cp bootstrap_files/bootstrap.xml s3://<bootstrap-bucket>/config/



Security Best Practices:

Never use default passwords in production
Use strong, unique passwords (minimum 12 characters with mixed case, numbers, and symbols)
Store password hashes securely and never commit plaintext passwords to version control
Consider using AWS Secrets Manager or Parameter Store for credential management
Rotate passwords regularly according to your security policy


Ubuntu Instances

Username: ubuntu
SSH Key: Uses the EC2 key pair specified in terraform.tfvars

Accessing the Environment
1. VM-Series Management
After deployment, the firewalls are accessible via:

Serial Console: Through AWS EC2 Serial Console
SSH: Via EC2 Instance Connect Endpoint (private access only)

To access via SSH:
bash# Get instance IDs from Terraform output
terraform output

# Use AWS EC2 Instance Connect
aws ec2-instance-connect open-tunnel \
  --instance-id <instance-id> \
  --instance-connect-endpoint-id <eice-id> \
  --remote-port 22 \
  --local-port 2222 &

ssh -p 2222 -i ~/.ssh/gwlb-us.pem admin@localhost
2. Application Access
The demo web application is accessible via the Application Load Balancer:
bashterraform output spk1_alb_url
Network Traffic Flows
North-South Traffic (Internet to Application)

Internet → ALB in Spoke1
ALB → GWLB Endpoint in Spoke1
GWLB Endpoint → GWLB → VM-Series (inspection)
VM-Series → Back through GWLB → Application Servers

East-West Traffic (Spoke to Spoke)

Spoke1 VM → Transit Gateway
Transit Gateway → Inspection VPC
Inspection VPC → GWLB Endpoint → VM-Series (inspection)
VM-Series → Transit Gateway → Spoke2 VM

Bootstrap Configuration
The VM-Series firewalls are automatically configured with:

Management Interface: DHCP with AWS DNS
Dataplane Interfaces: Trust (eth1/1) and Untrust (eth1/2)
Security Zones: trust and untrust
Virtual Router: Static routes for RFC1918 with path monitoring
Security Policies:

gwlb-probe: GWLB health checks
east-west: Spoke-to-spoke communication
outbound: Internet access from spokes
inbound-web: Web traffic to Spoke1


NAT Policy: Outbound NAT for internet access
AWS GWLB Plugin: Enabled for GENEVE encapsulation

Modifying Bootstrap Configuration

Edit bootstrap_files/bootstrap.xml with your configuration
Generate and update password hashes as described in the Security section above
Update the Git repository
Pull changes in CloudShell:
bashgit pull origin main

Update S3:
bashaws s3 cp bootstrap_files/bootstrap.xml s3://<bootstrap-bucket>/config/

For existing firewalls, factory reset to apply new bootstrap:
bashrequest system private-data-reset


File Structure
.
├── bootstrap_files/          # VM-Series bootstrap configuration
│   ├── bootstrap.xml         # Main configuration file
│   ├── init-cfg.txt         # Initial configuration
│   └── authcodes            # License auth codes (if applicable)
├── modules/                 # Terraform modules
│   ├── s3_bootstrap/        # S3 bootstrap bucket module
│   ├── subnets/            # Subnet creation module
│   ├── vmseries/           # VM-Series deployment module
│   └── route_table_association/  # Route table association module
├── scripts/                 # User data scripts
│   └── web_startup.yml.tpl # Web server initialization
├── terraform.tfvars        # Variable definitions
├── variables.tf            # Variable declarations
├── providers.tf            # Provider configuration
├── vmseries_vpc.tf         # Inspection VPC configuration
├── vmseries.tf             # VM-Series firewall deployment
├── gwlb.tf                 # Gateway Load Balancer configuration
├── tgw.tf                  # Transit Gateway configuration
├── spokes.tf               # Spoke VPCs configuration
├── DIAGRAM.png             # Architecture diagram image
└── README.md               # This file
Troubleshooting
VM-Series Not Bootstrapping
The most critical aspect is whether the firewall bootstrapped correctly. If bootstrap succeeds, the configuration is applied and the firewall should be working. If not, the firewall will not function properly.

Check bootstrap status via serial console:
bashaws ec2-serial-console connect --instance-id <instance-id> --serial-port 0

Once logged in, verify bootstrap completion:
bashshow system info | match "sw-version"
show jobs processed

Check if bootstrap configuration was applied:
bashshow config running

Verify IAM role has proper S3 read permissions for the bootstrap bucket
Check bootstrap logs:
bashdebug user-id bootstrap-status
less mp-log pan_dha.log


GWLB Health Checks Failing

Verify security policies allow health check traffic:
bashshow policy name gwlb-probe

Check VM-Series interfaces are up:
bashshow interface ethernet1/1
show interface ethernet1/2

Verify GWLB plugin is enabled:
bashshow plugins vm_series_gwlb status

Check GWLB association:
bashshow plugins vm_series_gwlb zones


Security Considerations
This is a DEMO environment with simplified security settings:

Default passwords are published - Change immediately for any non-demo use (see password hash generation section)
Security groups are permissive - Tighten for production
All traffic inspection is enabled - Tune policies for your requirements
Bootstrap bucket is accessible - Restrict access in production
Password hashes should be rotated - Update regularly according to security policy

Clean Up
To destroy all resources and avoid charges:
bashterraform destroy -auto-approve
This will remove:

All EC2 instances (VM-Series and Ubuntu servers)
VPCs and networking components
Gateway Load Balancer and endpoints
Transit Gateway and attachments
S3 bootstrap bucket

Advanced Configuration
Scaling VM-Series
Adjust the firewall count in terraform.tfvars:
hclfw_count_az1 = 2  # Number of firewalls in AZ1
fw_count_az2 = 2  # Number of firewalls in AZ2
Changing Instance Types
Modify in terraform.tfvars:
hclfw_size    = "c6in.xlarge"  # For VM-Series
spoke_size = "t3.micro"      # For Ubuntu instances
Adding More Spokes

Copy the spoke configuration pattern from spokes.tf
Add Transit Gateway attachment
Update route tables
Add security policies in bootstrap.xml

Support and Documentation

Palo Alto Networks: VM-Series Deployment Guide
AWS GWLB: Gateway Load Balancer Documentation
Terraform: AWS Provider Documentation
PAN-OS CLI: Command Reference

Known Issues

Bootstrap takes 10-15 minutes on first boot
Serial console may show login prompt before bootstrap completes
GWLB health checks may take 2-3 minutes to pass after firewall boots
EC2 Instance Connect Endpoint has quota limits per VPC
Password hash format must match PAN-OS version requirements

Contributing
Feel free to submit issues and enhancement requests!
License
This demo is provided as-is for educational purposes. Ensure you have appropriate licenses for VM-Series firewalls before deployment.

Last Updated: September 2025
Terraform Version: >= 1.0
PAN-OS Version: 11.1.6
AWS Provider Version: ~> 5.0
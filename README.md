# VM-Series AWS Gateway Load Balancer with Transit Gateway Demo

## Overview

This Terraform project deploys a comprehensive hub-and-spoke network architecture on AWS using Palo Alto Networks VM-Series firewalls behind a Gateway Load Balancer (GWLB) for centralized security inspection. The architecture demonstrates enterprise-grade network segmentation and security inspection patterns using AWS native services integrated with VM-Series next-generation firewalls.

## Architecture Diagram

For a visual representation of the network topology, open the [Architecture Diagram](docs/architecture-diagram.html) in your browser. The interactive diagram shows:
- All VPC interconnections with CIDR blocks (10.210.x.x, 10.211.x.x, 10.212.x.x)
- VM-Series firewall placement in Inspection VPC
- Gateway Load Balancer and GWLB Endpoints configuration
- Transit Gateway with route tables
- Traffic flow patterns (North-South and East-West)
- Component relationships and network segmentation

To view: Open `docs/architecture-diagram.html` in any modern web browser (works offline).

## Architecture Components

### Core Infrastructure
- **Inspection VPC**: Central security VPC hosting VM-Series firewalls (10.210.0.0/16)
- **Spoke1 VPC**: Application VPC with web servers behind ALB (10.211.0.0/16)
- **Spoke2 VPC**: Jump host/bastion VPC for management (10.212.0.0/16)
- **Transit Gateway**: Central routing hub connecting all VPCs
- **Gateway Load Balancer**: Distributes traffic to VM-Series firewalls for inspection

### Security Components
- **VM-Series Firewalls**: PAN-OS 11.1.6 running on c6in.xlarge instances
- **Bootstrap Configuration**: Automated firewall configuration via S3
- **Security Policies**: Pre-configured rules for east-west and north-south traffic

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0
3. **AWS CLI** configured with credentials
4. **EC2 Key Pair** named "gwlb-us" in us-west-1 region
5. **VM-Series License** (BYOL, Bundle1, or Bundle2)

## Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/vmseries-aws-gwlb-tgw.git
cd vmseries-aws-gwlb-tgw
```

### 2. Configure Variables
Edit `terraform.tfvars` to match your environment:
```hcl
region         = "us-west-1"
key_name       = "gwlb-us"           # Your EC2 key pair name
your_public_ip = "YOUR_IP/32"        # Your public IP for management access
fw_license     = "byol"              # or "bundle1" or "bundle2"
```

### 3. Deploy Infrastructure
```bash
terraform init
terraform plan
terraform apply -auto-approve
```

Deployment takes approximately 15-20 minutes.

## Default Credentials

### VM-Series Firewalls
- **Username**: `admin` or `paloalto`
- **Password**: `PaloAlt0123!`
- **SSH Key**: Uses the EC2 key pair specified in terraform.tfvars

> **Note**: This is a demo environment. Change these credentials immediately for production use.

### Ubuntu Instances
- **Username**: `ubuntu`
- **SSH Key**: Uses the EC2 key pair specified in terraform.tfvars

## Accessing the Environment

### 1. VM-Series Management
After deployment, the firewalls are accessible via:
- **Serial Console**: Through AWS EC2 Serial Console
- **SSH**: Via EC2 Instance Connect Endpoint (private access only)

To access via SSH:
```bash
# Get instance IDs from Terraform output
terraform output

# Use AWS EC2 Instance Connect
aws ec2-instance-connect open-tunnel \
  --instance-id <instance-id> \
  --instance-connect-endpoint-id <eice-id> \
  --remote-port 22 \
  --local-port 2222 &

ssh -p 2222 -i ~/.ssh/gwlb-us.pem admin@localhost
```

### 2. Application Access
The demo web application is accessible via the Application Load Balancer:
```bash
terraform output spk1_alb_url
```

### 3. Jump Host Access
SSH to the Spoke2 jump host for testing east-west traffic:
```bash
# Get the private IP from output
terraform output spk2_private_ip

# Access via bastion or VPN (no public IP due to security policies)
```

## Network Traffic Flows

### North-South Traffic (Internet to Application)
1. Internet → ALB in Spoke1
2. ALB → GWLB Endpoint in Spoke1
3. GWLB Endpoint → GWLB → VM-Series (inspection)
4. VM-Series → Back through GWLB → Application Servers

### East-West Traffic (Spoke to Spoke)
1. Spoke1 VM → Transit Gateway
2. Transit Gateway → Inspection VPC
3. Inspection VPC → GWLB Endpoint → VM-Series (inspection)
4. VM-Series → Transit Gateway → Spoke2 VM

## Bootstrap Configuration

The VM-Series firewalls are automatically configured with:
- **Management Interface**: DHCP with AWS DNS
- **Dataplane Interfaces**: Trust (eth1/1) and Untrust (eth1/2)
- **Security Zones**: trust and untrust
- **Virtual Router**: Static routes for RFC1918 with path monitoring
- **Security Policies**:
  - `gwlb-probe`: GWLB health checks
  - `east-west`: Spoke-to-spoke communication
  - `outbound`: Internet access from spokes
  - `inbound-web`: Web traffic to Spoke1
- **NAT Policy**: Outbound NAT for internet access
- **AWS GWLB Plugin**: Enabled for GENEVE encapsulation

### Modifying Bootstrap Configuration

1. Edit `bootstrap_files/bootstrap.xml` with your configuration
2. Update the Git repository
3. Pull changes in CloudShell:
   ```bash
   git pull origin main
   ```
4. Update S3:
   ```bash
   aws s3 cp bootstrap_files/bootstrap.xml s3://<bootstrap-bucket>/config/
   ```
5. For existing firewalls, factory reset to apply new bootstrap:
   ```bash
   request system private-data-reset
   ```

## File Structure

```
.
├── bootstrap_files/          # VM-Series bootstrap configuration
│   ├── bootstrap.xml         # Main configuration file
│   ├── init-cfg.txt         # Initial configuration
│   └── authcodes            # License auth codes (if applicable)
├── docs/                    # Documentation and diagrams
│   └── architecture-diagram.html  # Interactive network topology diagram
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
└── README.md               # This file
```

## Troubleshooting

### VM-Series Not Bootstrapping
1. Check S3 bucket accessibility:
   ```bash
   aws s3 ls s3://<bootstrap-bucket>/config/
   ```
2. Verify IAM role has S3 read permissions
3. Check bootstrap logs via serial console

### GWLB Health Checks Failing
1. Verify security policies allow health check traffic
2. Check VM-Series interfaces are up:
   ```bash
   show interface all
   ```
3. Verify GWLB plugin is enabled:
   ```bash
   show plugins vm_series aws gwlb
   ```

### Cannot Access VM-Series Management
1. Verify security group allows your IP
2. Check EC2 Instance Connect Endpoint is in correct subnet
3. Use serial console as fallback:
   ```bash
   aws ec2-serial-console connect --instance-id <instance-id> --serial-port 0
   ```

### Traffic Not Being Inspected
1. Check Transit Gateway route tables
2. Verify GWLB endpoints are in route tables
3. Check VM-Series traffic logs:
   ```bash
   show log traffic
   ```

## Security Considerations

This is a **DEMO environment** with simplified security settings:

- **Default passwords are published** - Change immediately for any non-demo use
- **Security groups are permissive** - Tighten for production
- **All traffic inspection is enabled** - Tune policies for your requirements
- **Bootstrap bucket is accessible** - Restrict access in production

## Clean Up

To destroy all resources and avoid charges:
```bash
terraform destroy -auto-approve
```

This will remove:
- All EC2 instances (VM-Series and Ubuntu servers)
- VPCs and networking components
- Gateway Load Balancer and endpoints
- Transit Gateway and attachments
- S3 bootstrap bucket

## Advanced Configuration

### Scaling VM-Series
Adjust the firewall count in `terraform.tfvars`:
```hcl
fw_count_az1 = 2  # Number of firewalls in AZ1
fw_count_az2 = 2  # Number of firewalls in AZ2
```

### Changing Instance Types
Modify in `terraform.tfvars`:
```hcl
fw_size    = "c6in.xlarge"  # For VM-Series
spoke_size = "t3.micro"      # For Ubuntu instances
```

### Adding More Spokes
1. Copy the spoke configuration pattern from `spokes.tf`
2. Add Transit Gateway attachment
3. Update route tables
4. Add security policies in bootstrap.xml

## Support and Documentation

- **Palo Alto Networks**: [VM-Series Deployment Guide](https://docs.paloaltonetworks.com/vm-series)
- **AWS GWLB**: [Gateway Load Balancer Documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/gateway/)
- **Terraform**: [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## Known Issues

1. **Bootstrap takes 10-15 minutes** on first boot
2. **Serial console** may show login prompt before bootstrap completes
3. **GWLB health checks** may take 2-3 minutes to pass after firewall boots
4. **EC2 Instance Connect Endpoint** has quota limits per VPC

## Contributing

Feel free to submit issues and enhancement requests!

## License

This demo is provided as-is for educational purposes. Ensure you have appropriate licenses for VM-Series firewalls before deployment.

---

**Last Updated**: September 2025
**Terraform Version**: >= 1.0
**PAN-OS Version**: 11.1.6
**AWS Provider Version**: ~> 5.0
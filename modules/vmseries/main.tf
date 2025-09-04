# =============================================================================
# VM-SERIES MODULE (PHASE 1 - BACKWARD COMPATIBLE)
# =============================================================================

# =============================================================================
# DATA SOURCES
# =============================================================================

# Get VM-Series AMI
data "aws_ami" "vmseries" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "owner-alias"
    values = ["aws-marketplace"]
  }

  filter {
    name   = "product-code"
    values = [var.license_type_map[var.license]]
  }

  filter {
    name   = "name"
    values = ["PA-VM-AWS-${var.panos}*"]
  }
}

# Get current AWS region and account
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# =============================================================================
# LOCALS FOR CONFIGURATION
# =============================================================================

locals {
  # Calculate actual VM count
  vm_count = var.vm_count

  # ✅ BACKWARD COMPATIBILITY: Use new variable if provided, otherwise fall back to old one
  mgmt_cidrs = var.mgmt_sg_cidrs != null ? var.mgmt_sg_cidrs : var.eni0_sg_prefix

  # Common tags for all resources
  common_tags = merge(
    {
      Name         = var.name
      Environment  = var.environment
      Project      = var.project_name
      Module       = "vm-series"
      PanosVersion = var.panos
      License      = var.license
      ManagedBy    = "terraform"
    },
    var.common_tags
  )
}

# =============================================================================
# SECURITY GROUPS
# =============================================================================

# Management Security Group
resource "aws_security_group" "management" {
  name_prefix = "${var.name}-mgmt-"
  description = "VM-Series Management Interface Security Group"
  vpc_id      = var.vpc_id

  # HTTPS Management Access
  ingress {
    description = "HTTPS Management Access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = local.mgmt_cidrs
  }

  # SSH Management Access
  ingress {
    description = "SSH Management Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.mgmt_cidrs
  }

  # Outbound internet access
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-mgmt-sg"
    Type = "Management"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Data Plane Security Group
resource "aws_security_group" "data" {
  name_prefix = "${var.name}-data-"
  description = "VM-Series Data Interfaces Security Group"
  vpc_id      = var.vpc_id

  # Allow all traffic for firewall inspection
  ingress {
    description = "All inbound traffic for inspection"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-data-sg"
    Type = "DataPlane"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# NETWORK INTERFACES
# =============================================================================

# ENI0 - Trust/Data Interface
resource "aws_network_interface" "eni0" {
  count           = local.vm_count
  subnet_id       = var.eni0_subnet
  security_groups = [aws_security_group.data.id]
  
  source_dest_check = false
  description       = "${var.name}-${count.index}-trust"

  tags = merge(local.common_tags, {
    Name = "${var.name}-${count.index}-eni0"
    Type = "trust"
  })
}

# ENI1 - Management Interface
resource "aws_network_interface" "eni1" {
  count           = local.vm_count
  subnet_id       = var.eni1_subnet
  security_groups = [aws_security_group.management.id]
  
  source_dest_check = true  # Management interface should have source/dest check
  description       = "${var.name}-${count.index}-management"

  tags = merge(local.common_tags, {
    Name = "${var.name}-${count.index}-eni1"
    Type = "management"
  })
}

# ENI2 - Untrust/Data Interface (Optional)
resource "aws_network_interface" "eni2" {
  count           = var.eni2_subnet != null ? local.vm_count : 0
  subnet_id       = var.eni2_subnet
  security_groups = [aws_security_group.data.id]
  
  source_dest_check = false
  description       = "${var.name}-${count.index}-untrust"

  tags = merge(local.common_tags, {
    Name = "${var.name}-${count.index}-eni2"
    Type = "untrust"
  })
}

# =============================================================================
# ELASTIC IPs
# =============================================================================

# EIP for ENI0 (Trust) - if requested
resource "aws_eip" "eni0" {
  count             = var.eni0_public_ip ? local.vm_count : 0
  domain            = "vpc"
  network_interface = aws_network_interface.eni0[count.index].id

  tags = merge(local.common_tags, {
    Name = "${var.name}-${count.index}-eni0-eip"
    Type = "Trust"
  })

  depends_on = [aws_network_interface.eni0]
}

# EIP for ENI1 (Management)
resource "aws_eip" "eni1" {
  count             = var.eni1_public_ip ? local.vm_count : 0
  domain            = "vpc"
  network_interface = aws_network_interface.eni1[count.index].id

  tags = merge(local.common_tags, {
    Name = "${var.name}-${count.index}-eni1-eip"
    Type = "Management"
  })

  depends_on = [aws_network_interface.eni1]
}

# EIP for ENI2 (Untrust) - if interface exists and requested
resource "aws_eip" "eni2" {
  count             = (var.eni2_subnet != null && var.eni2_public_ip) ? local.vm_count : 0
  domain            = "vpc"
  network_interface = aws_network_interface.eni2[count.index].id

  tags = merge(local.common_tags, {
    Name = "${var.name}-${count.index}-eni2-eip"
    Type = "Untrust"
  })

  depends_on = [aws_network_interface.eni2]
}

# =============================================================================
# VM-SERIES INSTANCES
# =============================================================================

resource "aws_instance" "vmseries" {
  count = local.vm_count

  # Basic instance configuration
  ami           = data.aws_ami.vmseries.image_id
  instance_type = var.size
  key_name      = var.key_name

  # Performance and monitoring
  ebs_optimized = true
  monitoring    = var.enable_detailed_monitoring

  # Security and IAM
  iam_instance_profile = var.instance_profile

  # Shutdown behavior
  disable_api_termination              = var.enable_termination_protection
  instance_initiated_shutdown_behavior = "stop"

  # User data for bootstrap
  user_data = var.user_data != "" ? var.user_data : null

  # Storage configuration
  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    encrypted             = var.root_volume_encrypted
    delete_on_termination = true
  }

  # Network interfaces
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.eni0[count.index].id
  }

  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.eni1[count.index].id
  }

  # Optional third interface
  dynamic "network_interface" {
    for_each = var.eni2_subnet != null ? [1] : []
    content {
      device_index         = 2
      network_interface_id = aws_network_interface.eni2[count.index].id
    }
  }

  # Comprehensive tagging
  tags = merge(local.common_tags, {
    Name = "${var.name}-${count.index}"
    Type = "VM-Series"
    AZ   = aws_network_interface.eni0[count.index].availability_zone
  })

  # Dependencies
  depends_on = [
    aws_network_interface.eni0,
    aws_network_interface.eni1,
    aws_network_interface.eni2,
    aws_eip.eni0,
    aws_eip.eni1,
    aws_eip.eni2
  ]

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      ami,       # Ignore AMI changes to prevent accidental upgrades
      user_data  # Ignore user_data changes after initial deployment
    ]
  }
}
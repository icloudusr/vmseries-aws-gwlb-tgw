# =============================================================================
# VM-SERIES MODULE (PHASE 1 - BACKWARD COMPATIBLE) - UPDATED FOR FOR_EACH
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
  # ✅ BACKWARD COMPATIBILITY: Use new variable if provided, otherwise fall back to old one
  mgmt_cidrs = var.mgmt_sg_cidrs != null ? var.mgmt_sg_cidrs : var.eni0_sg_prefix

<<<<<<< HEAD
  # ✅ NEW: Create instance map for for_each
  eni_instances = {
    for i in range(var.vm_count) : "instance-${i}" => {
      index = i
    }
  }
  
  # ✅ FIXED: Remove computed dependency - always use base instances
  eni2_instances = local.eni_instances

=======
  # ✅ NEW: Create instance map for for_each
  eni_instances = {
    for i in range(var.vm_count) : "instance-${i}" => {
      index = i
    }
  }
  
  # ✅ NEW: ENI2 instances (only when subnet provided)
  eni2_instances = var.eni2_subnet != null ? local.eni_instances : {}

>>>>>>> bbad697f65028432b84e97f8693bcfa473f24e52
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
# NETWORK INTERFACES - CONVERTED TO FOR_EACH
# =============================================================================

# ENI0 - Trust/Data Interface
resource "aws_network_interface" "eni0" {
  for_each = local.eni_instances
  
  subnet_id         = var.eni0_subnet
  security_groups   = [aws_security_group.data.id]
  source_dest_check = false
  description       = "${var.name}-${each.value.index}-trust"

  tags = merge(local.common_tags, {
    Name = "${var.name}-${each.value.index}-eni0"
    Type = "trust"
  })
}

# ENI1 - Management Interface
resource "aws_network_interface" "eni1" {
  for_each = local.eni_instances
  
  subnet_id         = var.eni1_subnet
  security_groups   = [aws_security_group.management.id]
  source_dest_check = true  # Management interface should have source/dest check
  description       = "${var.name}-${each.value.index}-management"

  tags = merge(local.common_tags, {
    Name = "${var.name}-${each.value.index}-eni1"
    Type = "management"
  })
}

# ENI2 - Untrust/Data Interface (Optional)
resource "aws_network_interface" "eni2" {
<<<<<<< HEAD
  for_each = var.create_eni2 ? local.eni_instances : {}  # ✅ FIXED: Use boolean control
=======
  for_each = local.eni2_instances
>>>>>>> bbad697f65028432b84e97f8693bcfa473f24e52
  
  subnet_id         = var.eni2_subnet
  security_groups   = [aws_security_group.data.id]
  source_dest_check = false
  description       = "${var.name}-${each.value.index}-untrust"

  tags = merge(local.common_tags, {
    Name = "${var.name}-${each.value.index}-eni2"
    Type = "untrust"
  })
}

# =============================================================================
# ELASTIC IPs - CONVERTED TO FOR_EACH
# =============================================================================

# EIP for ENI0 (Trust) - if requested
resource "aws_eip" "eni0" {
  for_each = var.eni0_public_ip ? local.eni_instances : {}
  
  domain            = "vpc"
  network_interface = aws_network_interface.eni0[each.key].id

  tags = merge(local.common_tags, {
    Name = "${var.name}-${each.value.index}-eni0-eip"
    Type = "Trust"
  })

  depends_on = [aws_network_interface.eni0]
}

# EIP for ENI1 (Management)
resource "aws_eip" "eni1" {
  for_each = var.eni1_public_ip ? local.eni_instances : {}
  
  domain            = "vpc"
  network_interface = aws_network_interface.eni1[each.key].id

  tags = merge(local.common_tags, {
    Name = "${var.name}-${each.value.index}-eni1-eip"
    Type = "Management"
  })

  depends_on = [aws_network_interface.eni1]
}

# EIP for ENI2 (Untrust) - if interface exists and requested
resource "aws_eip" "eni2" {
<<<<<<< HEAD
  for_each = var.eni2_public_ip && var.create_eni2 ? local.eni_instances : {}  # ✅ FIXED: Add create_eni2 check
  
=======
  for_each = var.eni2_public_ip ? local.eni2_instances : {}
  
>>>>>>> bbad697f65028432b84e97f8693bcfa473f24e52
  domain            = "vpc"
  network_interface = aws_network_interface.eni2[each.key].id

  tags = merge(local.common_tags, {
    Name = "${var.name}-${each.value.index}-eni2-eip"
    Type = "Untrust"
  })

  depends_on = [aws_network_interface.eni2]
}

# =============================================================================
# VM-SERIES INSTANCES - CONVERTED TO FOR_EACH
# =============================================================================

resource "aws_instance" "vmseries" {
  for_each = local.eni_instances

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
    network_interface_id = aws_network_interface.eni0[each.key].id
  }

  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.eni1[each.key].id
  }

  # Optional third interface
  dynamic "network_interface" {
    for_each = var.create_eni2 ? [1] : []  # ✅ FIXED: Use boolean control
    content {
      device_index         = 2
      network_interface_id = aws_network_interface.eni2[each.key].id
    }
  }

  # Comprehensive tagging
  tags = merge(local.common_tags, {
    Name = "${var.name}-${each.value.index}"
    Type = "VM-Series"
    AZ   = aws_network_interface.eni0[each.key].availability_zone
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
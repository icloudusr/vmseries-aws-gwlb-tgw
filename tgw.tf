# =============================================================================
# TRANSIT GATEWAY CONFIGURATION
# =============================================================================

resource "aws_ec2_transit_gateway" "main" {
  description                     = "VM-Series Demo Transit Gateway"
  vpn_ecmp_support                = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"

  tags = {
    Name = "${var.fw_prefix}-tgw"
  }
}

# =============================================================================
# SECURITY VPC ATTACHMENT
# =============================================================================

resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
  vpc_id = aws_vpc.security.id

  subnet_ids = [
    module.vmseries_subnets.subnet_ids["tgw-az1"],
    module.vmseries_subnets.subnet_ids["tgw-az2"]
  ]

  transit_gateway_id                              = aws_ec2_transit_gateway.main.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  appliance_mode_support                          = "enable"

  tags = {
    Name = "${var.fw_prefix}-attachment"
  }
}

# =============================================================================
# SPK1 VPC ATTACHMENT
# =============================================================================

resource "aws_ec2_transit_gateway_vpc_attachment" "spk1_attachment" {
  vpc_id = aws_vpc.spk1.id

  subnet_ids = [
    module.spk1_subnets.subnet_ids["vm-az1"],
    module.spk1_subnets.subnet_ids["vm-az2"]
  ]

  transit_gateway_id                              = aws_ec2_transit_gateway.main.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "${var.spk1_prefix}-attachment"
  }
}

# =============================================================================
# SPK2 VPC ATTACHMENT
# =============================================================================

resource "aws_ec2_transit_gateway_vpc_attachment" "spk2_attachment" {
  vpc_id = aws_vpc.spk2.id

  subnet_ids                                      = [aws_subnet.spk2.id]
  transit_gateway_id                              = aws_ec2_transit_gateway.main.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "${var.spk2_prefix}-attachment"
  }
}

# =============================================================================
# FIREWALL ROUTE TABLE (Security VPC Routes)
# =============================================================================

resource "aws_ec2_transit_gateway_route_table" "fw_common" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name = "${var.fw_prefix}-tgw-rt"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "fw_common" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.main.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.fw_common.id
}

# Routes for Security VPC to reach Spk VPCs
resource "aws_ec2_transit_gateway_route" "spk1" {
  destination_cidr_block         = var.spk1_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spk1_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.fw_common.id
}

resource "aws_ec2_transit_gateway_route" "spk2" {
  destination_cidr_block         = var.spk2_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spk2_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.fw_common.id
}

# =============================================================================
# SPK ROUTE TABLE (Spk VPCs Routes)
# =============================================================================

resource "aws_ec2_transit_gateway_route_table" "spk" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name = "spk-tgw-rt"
  }
}

# Default route for Spks - all traffic goes to Security VPC
resource "aws_ec2_transit_gateway_route" "spk" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.main.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spk.id
}

# Associate Spk VPCs with Spk Route Table
resource "aws_ec2_transit_gateway_route_table_association" "spk1" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spk1_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spk.id
}

resource "aws_ec2_transit_gateway_route_table_association" "spk2" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spk2_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spk.id
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "transit_gateway_id" {
  description = "Transit Gateway ID"
  value       = aws_ec2_transit_gateway.main.id
}

output "transit_gateway_route_table_ids" {
  description = "Transit Gateway route table IDs"
  value = {
    fw_common = aws_ec2_transit_gateway_route_table.fw_common.id
    spk     = aws_ec2_transit_gateway_route_table.spk.id
  }
}

output "tgw_attachment_ids" {
  description = "Transit Gateway VPC attachment IDs"
  value = {
    inspection = aws_ec2_transit_gateway_vpc_attachment.main.id
    spk1       = aws_ec2_transit_gateway_vpc_attachment.spk1_attachment.id
    spk2       = aws_ec2_transit_gateway_vpc_attachment.spk2_attachment.id
  }
}
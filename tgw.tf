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
# SPOKE1 VPC ATTACHMENT
# =============================================================================

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke1_attachment" {
  vpc_id = aws_vpc.spoke1.id

  subnet_ids = [
    module.spoke1_subnets.subnet_ids["vm-az1"],
    module.spoke1_subnets.subnet_ids["vm-az2"]
  ]

  transit_gateway_id                              = aws_ec2_transit_gateway.main.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "${var.spoke1_prefix}-attachment"
  }
}

# =============================================================================
# SPOKE2 VPC ATTACHMENT
# =============================================================================

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke2_attachment" {
  vpc_id = aws_vpc.spoke2.id

  subnet_ids                                      = [aws_subnet.spoke2.id]
  transit_gateway_id                              = aws_ec2_transit_gateway.main.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "${var.spoke2_prefix}-attachment"
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

# Routes for Security VPC to reach Spoke VPCs
resource "aws_ec2_transit_gateway_route" "spoke1" {
  destination_cidr_block         = var.spoke1_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke1_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.fw_common.id
}

resource "aws_ec2_transit_gateway_route" "spoke2" {
  destination_cidr_block         = var.spoke2_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke2_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.fw_common.id
}

# =============================================================================
# SPOKE ROUTE TABLE (Spoke VPCs Routes)
# =============================================================================

resource "aws_ec2_transit_gateway_route_table" "spoke" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name = "spoke-tgw-rt"
  }
}

# Default route for Spokes - all traffic goes to Security VPC
resource "aws_ec2_transit_gateway_route" "spoke" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.main.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

# Associate Spoke VPCs with Spoke Route Table
resource "aws_ec2_transit_gateway_route_table_association" "spoke1" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke1_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

resource "aws_ec2_transit_gateway_route_table_association" "spoke2" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke2_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
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
    spoke     = aws_ec2_transit_gateway_route_table.spoke.id
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
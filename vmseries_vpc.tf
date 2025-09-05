# =============================================================================
# INSPECTION VPC CONFIGURATION
# =============================================================================

resource "aws_vpc" "inspection" {
  cidr_block           = var.fw_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.fw_prefix}-inspection-vpc"
  }
}

resource "aws_internet_gateway" "inspection" {
  vpc_id = aws_vpc.inspection.id

  tags = {
    Name = "${var.fw_prefix}-inspection-igw"
  }
}

# =============================================================================
# INSPECTION VPC SUBNETS
# =============================================================================

module "vmseries_subnets" {
  source             = "./modules/subnets/"
  vpc_id             = aws_vpc.inspection.id
  subnet_name_prefix = "${var.fw_prefix}-"

  subnets = {
    "mgmt-az1" = {
      az   = data.aws_availability_zones.available.names[0]
      cidr = var.fw_cidr_mgmt_az1
    },
    "mgmt-az2" = {
      az   = data.aws_availability_zones.available.names[1]
      cidr = var.fw_cidr_mgmt_az2
    },
    "trust-az1" = {
      az   = data.aws_availability_zones.available.names[0]
      cidr = var.fw_cidr_trust_az1
    },
    "trust-az2" = {
      az   = data.aws_availability_zones.available.names[1]
      cidr = var.fw_cidr_trust_az2
    },
    "untrust-az1" = {
      az   = data.aws_availability_zones.available.names[0]
      cidr = var.fw_cidr_untrust_az1
    },
    "untrust-az2" = {
      az   = data.aws_availability_zones.available.names[1]
      cidr = var.fw_cidr_untrust_az2
    },
    "gwlbe-az1" = {
      az   = data.aws_availability_zones.available.names[0]
      cidr = var.fw_cidr_gwlbe_az1
    },
    "gwlbe-az2" = {
      az   = data.aws_availability_zones.available.names[1]
      cidr = var.fw_cidr_gwlbe_az2
    },
    "tgw-az1" = {
      az   = data.aws_availability_zones.available.names[0]
      cidr = var.fw_cidr_tgw_az1
    },
    "tgw-az2" = {
      az   = data.aws_availability_zones.available.names[1]
      cidr = var.fw_cidr_tgw_az2
    }
  }
}

# =============================================================================
# S3 VPC ENDPOINT FOR BOOTSTRAP
# =============================================================================

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.inspection.id
  service_name = "com.amazonaws.${var.region}.s3"
  
  route_table_ids = [
    aws_route_table.mgmt.id,
    aws_route_table.trust.id
  ]

  tags = {
    Name = "${var.fw_prefix}-s3-endpoint"
  }
}

# =============================================================================
# ROUTE TABLES - MANAGEMENT SUBNETS
# =============================================================================

resource "aws_route_table" "mgmt" {
  vpc_id = aws_vpc.inspection.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.inspection.id
  }

  tags = {
    Name = "${var.fw_prefix}-mgmt-rtb"
  }
}

# =============================================================================
# ROUTE TABLES - TRUST SUBNETS
# =============================================================================

resource "aws_route_table" "trust" {
  vpc_id = aws_vpc.inspection.id

  tags = {
    Name = "${var.fw_prefix}-trust-rtb"
  }
}

# =============================================================================
# ROUTE TABLES - UNTRUST SUBNETS
# =============================================================================

resource "aws_route_table" "untrust" {
  vpc_id = aws_vpc.inspection.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.inspection.id
  }

  tags = {
    Name = "${var.fw_prefix}-untrust-rtb"
  }
}

# =============================================================================
# ROUTE TABLES - GWLB ENDPOINT SUBNETS (AZ1)
# =============================================================================

resource "aws_route_table" "gwlbe_az1" {
  vpc_id = aws_vpc.inspection.id

  route {
    cidr_block         = "10.0.0.0/8"
    transit_gateway_id = aws_ec2_transit_gateway_vpc_attachment.main.transit_gateway_id
  }

  route {
    cidr_block         = "172.16.0.0/12"
    transit_gateway_id = aws_ec2_transit_gateway_vpc_attachment.main.transit_gateway_id
  }

  route {
    cidr_block         = "192.168.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway_vpc_attachment.main.transit_gateway_id
  }

  tags = {
    Name = "${var.fw_prefix}-gwlbe-az1-rtb"
  }
}

# =============================================================================
# ROUTE TABLES - GWLB ENDPOINT SUBNETS (AZ2)
# =============================================================================

resource "aws_route_table" "gwlbe_az2" {
  vpc_id = aws_vpc.inspection.id
  
  route {
    cidr_block         = "10.0.0.0/8"
    transit_gateway_id = aws_ec2_transit_gateway_vpc_attachment.main.transit_gateway_id
  }

  route {
    cidr_block         = "172.16.0.0/12"
    transit_gateway_id = aws_ec2_transit_gateway_vpc_attachment.main.transit_gateway_id
  }

  route {
    cidr_block         = "192.168.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway_vpc_attachment.main.transit_gateway_id
  }

  tags = {
    Name = "${var.fw_prefix}-gwlbe-az2-rtb"
  }
}

# =============================================================================
# ROUTE TABLES - TRANSIT GATEWAY SUBNETS (AZ1)
# =============================================================================

resource "aws_route_table" "tgw_az1" {
  vpc_id = aws_vpc.inspection.id

  route {
    cidr_block      = "0.0.0.0/0"
    vpc_endpoint_id = aws_vpc_endpoint.az1.id
  }

  tags = {
    Name = "${var.fw_prefix}-tgw-az1-rtb"
  }
}

# =============================================================================
# ROUTE TABLES - TRANSIT GATEWAY SUBNETS (AZ2)
# =============================================================================

resource "aws_route_table" "tgw_az2" {
  vpc_id = aws_vpc.inspection.id

  route {
    cidr_block      = "0.0.0.0/0"
    vpc_endpoint_id = aws_vpc_endpoint.az2.id
  }

  tags = {
    Name = "${var.fw_prefix}-tgw-az2-rtb"
  }
}

# =============================================================================
# ROUTE TABLE ASSOCIATIONS - GWLB ENDPOINT SUBNETS
# =============================================================================

module "rtb_association_gwlbe_az1" {
  source         = "./modules/route_table_association/"
  route_table_id = aws_route_table.gwlbe_az1.id

  subnet_ids = [
    module.vmseries_subnets.subnet_ids["gwlbe-az1"]
  ]
}

module "rtb_association_gwlbe_az2" {
  source         = "./modules/route_table_association/"
  route_table_id = aws_route_table.gwlbe_az2.id

  subnet_ids = [
    module.vmseries_subnets.subnet_ids["gwlbe-az2"]
  ]
}

# =============================================================================
# ROUTE TABLE ASSOCIATIONS - TRANSIT GATEWAY SUBNETS
# =============================================================================

module "rtb_association_tgw_az1" {
  source         = "./modules/route_table_association/"
  route_table_id = aws_route_table.tgw_az1.id

  subnet_ids = [
    module.vmseries_subnets.subnet_ids["tgw-az1"]
  ]
}

module "rtb_association_tgw_az2" {
  source         = "./modules/route_table_association/"
  route_table_id = aws_route_table.tgw_az2.id

  subnet_ids = [
    module.vmseries_subnets.subnet_ids["tgw-az2"]
  ]
}

# =============================================================================
# ROUTE TABLE ASSOCIATIONS - VM-SERIES SUBNETS
# =============================================================================

module "rtb_association_mgmt" {
  source         = "./modules/route_table_association/"
  route_table_id = aws_route_table.mgmt.id

  subnet_ids = [
    module.vmseries_subnets.subnet_ids["mgmt-az1"],
    module.vmseries_subnets.subnet_ids["mgmt-az2"]
  ]
}

module "rtb_association_trust" {
  source         = "./modules/route_table_association/"
  route_table_id = aws_route_table.trust.id

  subnet_ids = [
    module.vmseries_subnets.subnet_ids["trust-az1"],
    module.vmseries_subnets.subnet_ids["trust-az2"]
  ]
}

module "rtb_association_untrust" {
  source         = "./modules/route_table_association/"
  route_table_id = aws_route_table.untrust.id

  subnet_ids = [
    module.vmseries_subnets.subnet_ids["untrust-az1"],
    module.vmseries_subnets.subnet_ids["untrust-az2"]
  ]
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "security_vpc_id" {
  description = "Security VPC ID"
  value       = aws_vpc.inspection.id
}

output "security_vpc_cidr" {
  description = "Security VPC CIDR block"
  value       = aws_vpc.inspection.cidr_block
}

output "security_igw_id" {
  description = "Security VPC Internet Gateway ID"
  value       = aws_internet_gateway.inspection.id
}

output "inspection_route_table_ids" {
  description = "Inspection VPC route table IDs"
  value = {
    mgmt      = aws_route_table.mgmt.id
    trust     = aws_route_table.trust.id
    untrust   = aws_route_table.untrust.id
    gwlbe_az1 = aws_route_table.gwlbe_az1.id
    gwlbe_az2 = aws_route_table.gwlbe_az2.id
    tgw_az1   = aws_route_table.tgw_az1.id
    tgw_az2   = aws_route_table.tgw_az2.id
  }
}

output "s3_vpc_endpoint_id" {
  description = "S3 VPC Endpoint ID"
  value       = aws_vpc_endpoint.s3.id
}
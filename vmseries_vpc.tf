#------------------------------------------------------------------------------------------------------------------------------------
# Create firewall VPC, subnets, & IGW
resource "aws_vpc" "security" {
  cidr_block = var.fw_vpc_cidr

  tags = {
    Name = "${var.fw_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "security" {
  vpc_id = aws_vpc.security.id

  tags = {
    Name = "${var.fw_prefix}-vpc"
  }

}

module "vmseries_subnets" {
  source = "./modules/subnets/"
  vpc_id = aws_vpc.security.id
  subnet_name_prefix = "${var.fw_prefix}-"

  subnets = {
    mgmt-az1 = {
      az   = data.aws_availability_zones.available.names[0]
      cidr = var.fw_cidr_mgmt_az1
    },
    mgmt-az2 = {
      az   = data.aws_availability_zones.available.names[1]
      cidr = var.fw_cidr_mgmt_az2
    },
    trust-az1 = {
      az   = data.aws_availability_zones.available.names[0]
      cidr = var.fw_cidr_trust_az1
    },
    trust-az2 = {
      az   = data.aws_availability_zones.available.names[1]
      cidr = var.fw_cidr_trust_az2
    },
    untrust-az1 = {
      az   = data.aws_availability_zones.available.names[0]
      cidr = var.fw_cidr_untrust_az1
    },
    untrust-az2 = {
      az   = data.aws_availability_zones.available.names[1]
      cidr = var.fw_cidr_untrust_az2
    },
    gwlbe-az1 = {
      az   = data.aws_availability_zones.available.names[0]
      cidr = var.fw_cidr_gwlbe_az1
    },
    gwlbe-az2 = {
      az   = data.aws_availability_zones.available.names[1]
      cidr = var.fw_cidr_gwlbe_az2
    },
    tgw-az1 = {
      az   = data.aws_availability_zones.available.names[0]
      cidr = var.fw_cidr_tgw_az1
    },
    tgw-az2 = {
      az   = data.aws_availability_zones.available.names[1]
      cidr = var.fw_cidr_tgw_az2
    }

  }
}




#------------------------------------------------------------------------------------------------------------------------------------
# Create subnet route tables
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.security.id
  service_name = "com.amazonaws.${var.region}.s3"
  route_table_ids = [
    aws_route_table.mgmt.id,
    aws_route_table.trust.id
  ]
}

resource "aws_route_table" "mgmt" {
  vpc_id = aws_vpc.security.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.security.id
  }

  tags = {
    Name = "mgmt-rtb"
  }
}

resource "aws_route_table" "trust" {
  vpc_id = aws_vpc.security.id

  tags = {
    Name = "trust-rtb"
  }
}

resource "aws_route_table" "untrust" {
  vpc_id = aws_vpc.security.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.security.id
  }

  tags = {
    Name = "untrust-rtb"
  }
}

resource "aws_route_table" "gwlbe_az1" {
  vpc_id = aws_vpc.security.id

  route {
    cidr_block = "10.0.0.0/8"
    transit_gateway_id = aws_ec2_transit_gateway_vpc_attachment.main.transit_gateway_id
  }

  route {
    cidr_block = "172.16.0.0/12"
    transit_gateway_id = aws_ec2_transit_gateway_vpc_attachment.main.transit_gateway_id
  }

  route {
    cidr_block = "192.168.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway_vpc_attachment.main.transit_gateway_id
  }

  tags = {
    Name = "gwlbe-az1-rtb"
  }
}

resource "aws_route_table" "gwlbe_az2" {
  vpc_id = aws_vpc.security.id
  
  route {
    cidr_block = "10.0.0.0/8"
    transit_gateway_id = aws_ec2_transit_gateway_vpc_attachment.main.transit_gateway_id
  }

  route {
    cidr_block = "172.16.0.0/12"
    transit_gateway_id = aws_ec2_transit_gateway_vpc_attachment.main.transit_gateway_id
  }

  route {
    cidr_block = "192.168.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway_vpc_attachment.main.transit_gateway_id
  }

  tags = {
    Name = "gwlbe-az2-rtb"
  }
}

resource "aws_route_table" "tgw_az1" {
  vpc_id = aws_vpc.security.id

  route {
    cidr_block      = "0.0.0.0/0"
    vpc_endpoint_id = aws_vpc_endpoint.az1.id
  }

  tags = {
    Name = "tgw-az1-rtb"
  }
}

resource "aws_route_table" "tgw_az2" {
  vpc_id = aws_vpc.security.id

  route {
    cidr_block      = "0.0.0.0/0"
    vpc_endpoint_id = aws_vpc_endpoint.az2.id
  }

  tags = {
    Name = "tgw-az2-rtb"
  }
}

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
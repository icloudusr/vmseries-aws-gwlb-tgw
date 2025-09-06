# =============================================================================
# UBUNTU AMI DATA SOURCE - UPDATED TO 22.04 LTS
# =============================================================================

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# =============================================================================
# SPK1 VPC AND NETWORKING
# =============================================================================

resource "aws_vpc" "spk1" {
  cidr_block           = var.spk1_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.spk1_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "spk1" {
  vpc_id = aws_vpc.spk1.id

  tags = {
    Name = "${var.spk1_prefix}-igw"
  }
}

module "spk1_subnets" {
  source             = "./modules/subnets/"
  vpc_id             = aws_vpc.spk1.id
  subnet_name_prefix = "${var.spk1_prefix}-"

  subnets = {
    "vm-az1" = {
      az   = data.aws_availability_zones.available.names[0]
      cidr = var.spk1_vm_az1
    },
    "vm-az2" = {
      az   = data.aws_availability_zones.available.names[1]
      cidr = var.spk1_vm_az2
    },
    "alb-az1" = {
      az   = data.aws_availability_zones.available.names[0]
      cidr = var.spk1_alb_az1
    },
    "alb-az2" = {
      az   = data.aws_availability_zones.available.names[1]
      cidr = var.spk1_alb_az2
    },
    "gwlbe-az1" = {
      az   = data.aws_availability_zones.available.names[0]
      cidr = var.spk1_gwlbe_az1
    },
    "gwlbe-az2" = {
      az   = data.aws_availability_zones.available.names[1]
      cidr = var.spk1_gwlbe_az2
    }
  }
}

# =============================================================================
# SPK1 GWLB ENDPOINTS
# =============================================================================

resource "aws_vpc_endpoint" "spk1_az1" {
  service_name      = aws_vpc_endpoint_service.gwlb.service_name
  subnet_ids        = [module.spk1_subnets.subnet_ids["gwlbe-az1"]]
  vpc_endpoint_type = aws_vpc_endpoint_service.gwlb.service_type
  vpc_id            = aws_vpc.spk1.id

  tags = {
    Name = "${var.spk1_prefix}-endpoint-az1"
  }
}

resource "aws_vpc_endpoint" "spk1_az2" {
  service_name      = aws_vpc_endpoint_service.gwlb.service_name
  subnet_ids        = [module.spk1_subnets.subnet_ids["gwlbe-az2"]]
  vpc_endpoint_type = aws_vpc_endpoint_service.gwlb.service_type
  vpc_id            = aws_vpc.spk1.id

  tags = {
    Name = "${var.spk1_prefix}-endpoint-az2"
  }
}

# =============================================================================
# SPK1 ROUTE TABLES AND ASSOCIATIONS
# =============================================================================

resource "aws_route_table" "spk1_vm" {
  vpc_id = aws_vpc.spk1.id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway_vpc_attachment.spk1_attachment.transit_gateway_id
  }

  tags = {
    Name = "${var.spk1_prefix}-vm-rtb"
  }
}

resource "aws_route_table" "spk1_alb_az1" {
  vpc_id = aws_vpc.spk1.id

  route {
    cidr_block      = "0.0.0.0/0"
    vpc_endpoint_id = aws_vpc_endpoint.spk1_az1.id
  }

  tags = {
    Name = "${var.spk1_prefix}-alb-az1-rtb"
  }
}

resource "aws_route_table" "spk1_alb_az2" {
  vpc_id = aws_vpc.spk1.id

  route {
    cidr_block      = "0.0.0.0/0"
    vpc_endpoint_id = aws_vpc_endpoint.spk1_az2.id
  }

  tags = {
    Name = "${var.spk1_prefix}-alb-az2-rtb"
  }
}

resource "aws_route_table" "spk1_gwlbe" {
  vpc_id = aws_vpc.spk1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.spk1.id
  }

  tags = {
    Name = "${var.spk1_prefix}-gwlbe-rtb"
  }
}

resource "aws_route_table" "spk1_igw" {
  vpc_id = aws_vpc.spk1.id

  route {
    cidr_block      = var.spk1_alb_az1
    vpc_endpoint_id = aws_vpc_endpoint.spk1_az1.id
  }

  route {
    cidr_block      = var.spk1_alb_az2
    vpc_endpoint_id = aws_vpc_endpoint.spk1_az2.id
  }

  tags = {
    Name = "${var.spk1_prefix}-igw-rtb"
  }
}

# Route table associations
resource "aws_route_table_association" "spk1_vm_az1" {
  subnet_id      = module.spk1_subnets.subnet_ids["vm-az1"]
  route_table_id = aws_route_table.spk1_vm.id
}

resource "aws_route_table_association" "spk1_vm_az2" {
  subnet_id      = module.spk1_subnets.subnet_ids["vm-az2"]
  route_table_id = aws_route_table.spk1_vm.id
}

resource "aws_route_table_association" "spk1_alb_az1" {
  subnet_id      = module.spk1_subnets.subnet_ids["alb-az1"]
  route_table_id = aws_route_table.spk1_alb_az1.id
}

resource "aws_route_table_association" "spk1_alb_az2" {
  subnet_id      = module.spk1_subnets.subnet_ids["alb-az2"]
  route_table_id = aws_route_table.spk1_alb_az2.id
}

resource "aws_route_table_association" "spk1_gwlb_az1" {
  subnet_id      = module.spk1_subnets.subnet_ids["gwlbe-az1"]
  route_table_id = aws_route_table.spk1_gwlbe.id
}

resource "aws_route_table_association" "spk1_gwlb_az2" {
  subnet_id      = module.spk1_subnets.subnet_ids["gwlbe-az2"]
  route_table_id = aws_route_table.spk1_gwlbe.id
}

resource "aws_route_table_association" "spk1_igw" {
  gateway_id     = aws_internet_gateway.spk1.id
  route_table_id = aws_route_table.spk1_igw.id
}

# =============================================================================
# SPK1 SECURITY GROUP
# =============================================================================

resource "aws_security_group" "spk1_sg" {
  name_prefix = "${var.spk1_prefix}-sg-"
  description = "Security group for ${var.spk1_prefix} resources"
  vpc_id      = aws_vpc.spk1.id

  ingress {
    description = "Allow all inbound traffic for demo"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.spk1_prefix}-sg"
  }
}

# =============================================================================
# SPK1 EC2 INSTANCES AND LOAD BALANCER
# =============================================================================

resource "aws_network_interface" "spk1_vm1" {
  subnet_id         = module.spk1_subnets.subnet_ids["vm-az1"]
  security_groups   = [aws_security_group.spk1_sg.id]
  source_dest_check = false
  private_ips       = [var.spk1_vm1_ip]

  tags = {
    Name = "${var.spk1_prefix}-vm1-eni0"
  }
}

resource "aws_network_interface" "spk1_vm2" {
  subnet_id         = module.spk1_subnets.subnet_ids["vm-az2"]
  security_groups   = [aws_security_group.spk1_sg.id]
  source_dest_check = false
  private_ips       = [var.spk1_vm2_ip]

  tags = {
    Name = "${var.spk1_prefix}-vm2-eni0"
  }
}

resource "aws_instance" "spk1_vm1" {
  disable_api_termination = false
  ami                     = data.aws_ami.ubuntu.id
  instance_type           = var.spoke_size
  key_name                = var.key_name
  user_data               = base64encode(file("${path.module}/scripts/web_startup.yml.tpl"))

  root_block_device {
    delete_on_termination = true
    encrypted             = true
  }

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.spk1_vm1.id
  }

  tags = {
    Name = "${var.spk1_prefix}-vm1"
  }
}

resource "aws_instance" "spk1_vm2" {
  disable_api_termination = false
  ami                     = data.aws_ami.ubuntu.id
  instance_type           = var.spoke_size
  key_name                = var.key_name
  user_data               = base64encode(file("${path.module}/scripts/web_startup.yml.tpl"))

  root_block_device {
    delete_on_termination = true
    encrypted             = true
  }

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.spk1_vm2.id
  }

  tags = {
    Name = "${var.spk1_prefix}-vm2"
  }
}

# =============================================================================
# SPK1 APPLICATION LOAD BALANCER
# =============================================================================

resource "aws_lb" "spk1" {
  name               = "${var.spk1_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.spk1_sg.id]

  subnets = [
    module.spk1_subnets.subnet_ids["alb-az1"],
    module.spk1_subnets.subnet_ids["alb-az2"]
  ]

  enable_deletion_protection = false

  tags = {
    Name = "${var.spk1_prefix}-alb"
  }
}

resource "aws_lb_target_group" "spk1" {
  name        = "${var.spk1_prefix}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.spk1.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name = "${var.spk1_prefix}-tg"
  }
}

resource "aws_lb_target_group_attachment" "spk1_vm1" {
  target_group_arn = aws_lb_target_group.spk1.arn
  target_id        = var.spk1_vm1_ip
  port             = 80
}

resource "aws_lb_target_group_attachment" "spk1_vm2" {
  target_group_arn = aws_lb_target_group.spk1.arn
  target_id        = var.spk1_vm2_ip
  port             = 80
}

# ✅ MODERNIZED ALB LISTENER - Fixed deprecated syntax
resource "aws_lb_listener" "spk1" {
  load_balancer_arn = aws_lb.spk1.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.spk1.arn
        weight = 100
      }
    }
  }

  tags = {
    Name = "${var.spk1_prefix}-listener"
  }
}

# =============================================================================
# SPK2 VPC AND NETWORKING
# =============================================================================

resource "aws_vpc" "spk2" {
  cidr_block           = var.spk2_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.spk2_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "spk2" {
  vpc_id = aws_vpc.spk2.id

  tags = {
    Name = "${var.spk2_prefix}-igw"
  }
}

resource "aws_subnet" "spk2" {
  vpc_id            = aws_vpc.spk2.id
  cidr_block        = var.spk2_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.spk2_prefix}-vm-az1"
  }
}

# =============================================================================
# SPK2 ROUTING
# =============================================================================

resource "aws_route_table" "spk2" {
  vpc_id = aws_vpc.spk2.id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway_vpc_attachment.spk2_attachment.transit_gateway_id
  }

  route {
    cidr_block = var.your_public_ip
    gateway_id = aws_internet_gateway.spk2.id
  }

  tags = {
    Name = "${var.spk2_prefix}-rtb"
  }
}

resource "aws_route_table_association" "spk2" {
  subnet_id      = aws_subnet.spk2.id
  route_table_id = aws_route_table.spk2.id
}

# =============================================================================
# SPK2 SECURITY GROUP AND INSTANCE
# =============================================================================

resource "aws_security_group" "spk2_sg" {
  name_prefix = "${var.spk2_prefix}-sg-"
  description = "Security group for ${var.spk2_prefix} resources"
  vpc_id      = aws_vpc.spk2.id

  ingress {
    description = "Allow all inbound traffic for demo"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.spk2_prefix}-sg"
  }
}

resource "aws_network_interface" "spk2_vm1" {
  subnet_id         = aws_subnet.spk2.id
  security_groups   = [aws_security_group.spk2_sg.id]
  source_dest_check = false
  private_ips       = [var.spk2_vm1_ip]

  tags = {
    Name = "${var.spk2_prefix}-vm1-eni0"
  }
}

resource "aws_eip" "spk2_vm1" {
  domain            = "vpc"
  network_interface = aws_network_interface.spk2_vm1.id

  tags = {
    Name = "${var.spk2_prefix}-vm1-eip"
  }

  depends_on = [aws_internet_gateway.spk2]
}

resource "aws_instance" "spk2_vm1" {
  disable_api_termination = false
  ami                     = data.aws_ami.ubuntu.id
  instance_type           = var.spoke_size
  key_name                = var.key_name

  root_block_device {
    delete_on_termination = true
    encrypted             = true
  }

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.spk2_vm1.id
  }

  tags = {
    Name = "${var.spk2_prefix}-vm1"
  }

  depends_on = [aws_eip.spk2_vm1]
}

# =============================================================================
# OUTPUTS - ENHANCED FORMAT
# =============================================================================

output "spk1_alb_url" {
  description = "Spk1 Application Load Balancer URL"
  value       = "http://${aws_lb.spk1.dns_name}"
}

output "spk2_ssh_access" {
  description = "SSH command to access Spk2 jump host"
  value       = "ssh ubuntu@${aws_eip.spk2_vm1.public_ip} -i ~/.ssh/${var.key_name}.pem"
}

output "spk2_public_ip" {
  description = "Spk2 VM1 public IP address"
  value       = aws_eip.spk2_vm1.public_ip
}
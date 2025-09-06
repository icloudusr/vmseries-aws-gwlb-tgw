# =============================================================================
# GATEWAY LOAD BALANCER CONFIGURATION - UPDATED FOR FOR_EACH
# =============================================================================

locals {
  gwlb_name = "${var.fw_prefix}-gwlb"
}

# =============================================================================
# GATEWAY LOAD BALANCER
# =============================================================================

resource "aws_lb" "gwlb" {
  name               = local.gwlb_name
  internal           = false
  load_balancer_type = "gateway"

  subnets = [
    module.vmseries_subnets.subnet_ids["gwlbe-az1"],
    module.vmseries_subnets.subnet_ids["gwlbe-az2"]
  ]

  enable_cross_zone_load_balancing = true

  tags = {
    Name = local.gwlb_name
  }
}

# =============================================================================
# GATEWAY LOAD BALANCER TARGET GROUP
# =============================================================================

resource "aws_lb_target_group" "gwlb" {
  name        = "${local.gwlb_name}-tg"
  port        = 6081
  protocol    = "GENEVE"
  target_type = "instance"
  vpc_id      = aws_vpc.inspection.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
    port                = "traffic-port"
    protocol            = "TCP"
  }

  tags = {
    Name = "${local.gwlb_name}-tg"
  }
}

# =============================================================================
# TARGET GROUP ATTACHMENTS - UPDATED FOR FOR_EACH COMPATIBILITY
# =============================================================================

# AZ1 Target Group Attachments
resource "aws_lb_target_group_attachment" "az1" {
  count = var.fw_count_az1

  target_group_arn = aws_lb_target_group.gwlb.arn
  target_id        = module.fw_az1.instance_id[count.index]
  port             = 6081
}

# AZ2 Target Group Attachments - SIMPLIFIED TO COUNT
resource "aws_lb_target_group_attachment" "az2" {
  count = var.fw_count_az2

  target_group_arn = aws_lb_target_group.gwlb.arn
  target_id        = module.fw_az2.instance_id[count.index]
  port             = 6081
}

# =============================================================================
# GATEWAY LOAD BALANCER LISTENER
# =============================================================================

resource "aws_lb_listener" "gwlb" {
  load_balancer_arn = aws_lb.gwlb.id

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gwlb.id
  }

  tags = {
    Name = "${local.gwlb_name}-listener"
  }
}

# =============================================================================
# VPC ENDPOINT SERVICE
# =============================================================================

resource "aws_vpc_endpoint_service" "gwlb" {
  acceptance_required        = false
  gateway_load_balancer_arns = [aws_lb.gwlb.arn]

  allowed_principals = [
    data.aws_caller_identity.current.arn
  ]

  tags = {
    Name = "${local.gwlb_name}-endpoint-service"
  }
}

# =============================================================================
# SECURITY VPC ENDPOINT CONNECTIONS
# =============================================================================

resource "aws_vpc_endpoint" "az1" {
  service_name      = aws_vpc_endpoint_service.gwlb.service_name
  subnet_ids        = [module.vmseries_subnets.subnet_ids["gwlbe-az1"]]
  vpc_endpoint_type = aws_vpc_endpoint_service.gwlb.service_type
  vpc_id            = aws_vpc.inspection.id

  tags = {
    Name = "${local.gwlb_name}-endpoint-az1"
  }
}

resource "aws_vpc_endpoint" "az2" {
  service_name      = aws_vpc_endpoint_service.gwlb.service_name
  subnet_ids        = [module.vmseries_subnets.subnet_ids["gwlbe-az2"]]
  vpc_endpoint_type = aws_vpc_endpoint_service.gwlb.service_type
  vpc_id            = aws_vpc.inspection.id

  tags = {
    Name = "${local.gwlb_name}-endpoint-az2"
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "gwlb_arn" {
  description = "Gateway Load Balancer ARN"
  value       = aws_lb.gwlb.arn
}

output "gwlb_dns_name" {
  description = "Gateway Load Balancer DNS name"
  value       = aws_lb.gwlb.dns_name
}

output "gwlb_endpoint_service_name" {
  description = "GWLB endpoint service name for sharing with other accounts"
  value       = aws_vpc_endpoint_service.gwlb.service_name
}

output "gwlb_target_group_arn" {
  description = "Gateway Load Balancer target group ARN"
  value       = aws_lb_target_group.gwlb.arn
}

output "inspection_vpc_endpoint_ids" {
  description = "Inspection VPC endpoint IDs"
  value = {
    az1 = aws_vpc_endpoint.az1.id
    az2 = aws_vpc_endpoint.az2.id
  }
}

# =============================================================================
# TARGET GROUP ATTACHMENT INFO
# =============================================================================

output "target_group_attachments" {
  description = "Information about target group attachments"
  value = {
    az1_count     = length(aws_lb_target_group_attachment.az1)
    az2_count     = length(aws_lb_target_group_attachment.az2)
    total_targets = length(aws_lb_target_group_attachment.az1) + length(aws_lb_target_group_attachment.az2)
  }
}

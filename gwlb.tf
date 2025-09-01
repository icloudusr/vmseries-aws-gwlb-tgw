locals {
  gwlb_name = "${var.fw_prefix}-gwlb"
}

resource "aws_lb" "gwlb" {
  name               = local.gwlb_name
  internal           = false
  load_balancer_type = "gateway"
  subnets            = [module.vmseries_subnets.subnet_ids["gwlbe-az1"], module.vmseries_subnets.subnet_ids["gwlbe-az2"]]
  enable_cross_zone_load_balancing = true 
}

resource "aws_lb_target_group" "gwlb" {
  name        = "${local.gwlb_name}-tg"
  port        = 6081
  protocol    = "GENEVE"
  target_type = "instance"
  vpc_id      = aws_vpc.security.id
}

resource "aws_lb_target_group_attachment" "az1" {
  count            = var.fw_count_az1
  target_group_arn = aws_lb_target_group.gwlb.arn
  target_id        = element(module.fw_az1.instance_id, count.index)
  port             = 6081
}

resource "aws_lb_target_group_attachment" "az2" {
  count            = var.fw_count_az2
  target_group_arn = aws_lb_target_group.gwlb.arn
  target_id        = element(module.fw_az2.instance_id, count.index)
  port             = 6081
}


resource "aws_vpc_endpoint_service" "gwlb" {
  acceptance_required        = false
  gateway_load_balancer_arns = [aws_lb.gwlb.arn]

  tags = {
    Name = "${local.gwlb_name}-endpoint-service"
  }
}

resource "aws_vpc_endpoint" "az1" {
  service_name      = aws_vpc_endpoint_service.gwlb.service_name
  subnet_ids        = [module.vmseries_subnets.subnet_ids["gwlbe-az1"]]
  vpc_endpoint_type = aws_vpc_endpoint_service.gwlb.service_type
  vpc_id            = aws_vpc.security.id

  tags = {
    Name = "${local.gwlb_name}-endpoint-az1"
  }
}

resource "aws_vpc_endpoint" "az2" {
  service_name      = aws_vpc_endpoint_service.gwlb.service_name
  subnet_ids        = [module.vmseries_subnets.subnet_ids["gwlbe-az2"]]
  vpc_endpoint_type = aws_vpc_endpoint_service.gwlb.service_type
  vpc_id            = aws_vpc.security.id

  tags = {
    Name = "${local.gwlb_name}-endpoint-az2"
  }
}

resource "aws_lb_listener" "gwlb" {
  load_balancer_arn = aws_lb.gwlb.id

  default_action {
    target_group_arn = aws_lb_target_group.gwlb.id
    type             = "forward"
  }
}

output "maintenance_debug" {
  value = var.debug_mode ? "ssh -fN -i maintenance-${var.app_name}.pem -L 127.0.0.1:2345:${aws_lb.debug.0.dns_name}:2345 ubuntu@${aws_instance.maintenance.0.public_ip}" : null
}

# Setting up an NLB for the debug port. 
# This is probably unnecessary as you can specify the container's private IP.
# Leaving in for convenience of output maintenance debug
resource "aws_lb" "debug" {
  count              = var.debug_mode ? 1 : 0
  name               = "${var.app_name}-debug"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.private_subnet ? aws_subnet.private.*.id : aws_subnet.public.*.id
  security_groups    = [aws_security_group.debug[count.index].id]
  tags = {
    Name = var.app_name
  }
}

resource "aws_lb_target_group" "debug" {
  count       = var.debug_mode ? 1 : 0
  name        = "${var.app_name}-debug"
  port        = var.debug_port
  protocol    = "TCP"
  vpc_id      = aws_vpc.ashirt.id
  target_type = "ip"
  health_check {
    protocol = "TCP"
  }
}

resource "aws_lb_listener" "debug" {
  count             = var.debug_mode ? 1 : 0
  load_balancer_arn = aws_lb.debug[count.index].id
  port              = var.debug_port
  protocol          = "TCP"
  default_action {
    target_group_arn = aws_lb_target_group.debug[count.index].id
    type             = "forward"
  }
}

resource "aws_security_group_rule" "allow-ingress-web-debug-cidr" {
  count       = var.debug_mode ? 1 : 0
  type        = "ingress"
  to_port     = var.debug_port
  protocol    = "TCP"
  from_port   = var.debug_port
  cidr_blocks = [var.vpc_cidr]
  #source_security_group_id = aws_security_group.maintenance[count.index].id
  security_group_id = aws_security_group.debug[count.index].id
}


resource "aws_network_acl_rule" "ingress-debug" {
  count          = var.debug_mode ? 1 : 0
  network_acl_id = aws_network_acl.ashirt.id
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = var.debug_port
  to_port        = var.debug_port
}

resource "aws_security_group" "debug" {
  count       = var.debug_mode ? 1 : 0
  name        = "ashirt-debug"
  description = "Allow debug traffic to web"
  vpc_id      = aws_vpc.ashirt.id
  tags = {
    Name = "ashirt-debug-sg"
  }
}

resource "aws_security_group_rule" "allow-egress-debug" {
  count             = var.debug_mode ? 1 : 0
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  security_group_id = aws_security_group.debug[count.index].id
}

resource "aws_security_group_rule" "allow-ingress-debug" {
  count                    = var.debug_mode ? 1 : 0
  type                     = "ingress"
  to_port                  = var.debug_port
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.maintenance[count.index].id
  from_port                = var.debug_port
  security_group_id        = aws_security_group.debug[count.index].id
}

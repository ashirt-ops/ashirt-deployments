locals {
  app_port   = 8000
  nginx_port = 8080
}

# Public frontend load balancer
resource "aws_security_group" "frontend_alb" {
  name        = "${local.name}-frontend-alb"
  description = "Public ingress to the ashirt frontend load balancer"
  vpc_id      = aws_vpc.ashirt.id

  tags = {
    Name = "${local.name}-frontend-alb"
  }
}

resource "aws_security_group_rule" "frontend_alb_ingress_https" {
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = var.allow_frontend_cidrs
  security_group_id = aws_security_group.frontend_alb.id
}

resource "aws_security_group_rule" "frontend_alb_ingress_http" {
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = var.allow_frontend_cidrs
  security_group_id = aws_security_group.frontend_alb.id
}

resource "aws_security_group_rule" "frontend_alb_egress" {
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend_alb.id
}

# Frontend (nginx) ECS tasks
resource "aws_security_group" "frontend_ecs" {
  name        = "${local.name}-frontend-ecs"
  description = "Ingress to frontend tasks from the frontend load balancer"
  vpc_id      = aws_vpc.ashirt.id

  tags = {
    Name = "${local.name}-frontend-ecs"
  }
}

resource "aws_security_group_rule" "frontend_ecs_ingress" {
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = local.nginx_port
  to_port                  = local.nginx_port
  source_security_group_id = aws_security_group.frontend_alb.id
  security_group_id        = aws_security_group.frontend_ecs.id
}

resource "aws_security_group_rule" "frontend_ecs_egress" {
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend_ecs.id
}

# Internal ashirt-server load balancer
resource "aws_security_group" "server_alb" {
  name        = "${local.name}-server-alb"
  description = "Internal ingress to the ashirt-server load balancer"
  vpc_id      = aws_vpc.ashirt.id

  tags = {
    Name = "${local.name}-server-alb"
  }
}

resource "aws_security_group_rule" "server_alb_ingress_frontend" {
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = local.app_port
  to_port                  = local.app_port
  source_security_group_id = aws_security_group.frontend_ecs.id
  security_group_id        = aws_security_group.server_alb.id
}

resource "aws_security_group_rule" "server_alb_ingress_ocr" {
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = local.app_port
  to_port                  = local.app_port
  source_security_group_id = aws_security_group.ocr_worker_ecs.id
  security_group_id        = aws_security_group.server_alb.id
}

resource "aws_security_group_rule" "server_alb_egress" {
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.server_alb.id
}

# ashirt-server ECS tasks
resource "aws_security_group" "server_ecs" {
  name        = "${local.name}-server-ecs"
  description = "Ingress to ashirt-server tasks from the internal load balancer"
  vpc_id      = aws_vpc.ashirt.id

  tags = {
    Name = "${local.name}-server-ecs"
  }
}

resource "aws_security_group_rule" "server_ecs_ingress" {
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = local.app_port
  to_port                  = local.app_port
  source_security_group_id = aws_security_group.server_alb.id
  security_group_id        = aws_security_group.server_ecs.id
}

resource "aws_security_group_rule" "server_ecs_egress" {
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.server_ecs.id
}

# ocr-worker ECS tasks (outbound only; polls the ashirt-server API)
resource "aws_security_group" "ocr_worker_ecs" {
  name        = "${local.name}-ocr-worker-ecs"
  description = "Egress for ocr-worker tasks"
  vpc_id      = aws_vpc.ashirt.id

  tags = {
    Name = "${local.name}-ocr-worker-ecs"
  }
}

resource "aws_security_group_rule" "ocr_worker_ecs_egress" {
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ocr_worker_ecs.id
}

# Aurora cluster
resource "aws_security_group" "rds" {
  name        = "${local.name}-rds"
  description = "Ingress to the Aurora cluster from ashirt-server tasks"
  vpc_id      = aws_vpc.ashirt.id

  tags = {
    Name = "${local.name}-rds"
  }
}

resource "aws_security_group_rule" "rds_ingress_server" {
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  source_security_group_id = aws_security_group.server_ecs.id
  security_group_id        = aws_security_group.rds.id
}

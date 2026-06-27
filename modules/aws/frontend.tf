# Public, internet-facing load balancer for the nginx frontend.
resource "aws_lb" "frontend" {
  name               = "${local.name}-frontend"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.public[*].id
  security_groups    = [aws_security_group.frontend_alb.id]

  tags = {
    Name = "${local.name}-frontend"
  }
}

resource "aws_lb_target_group" "frontend" {
  name        = "${local.name}-frontend"
  port        = local.nginx_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.ashirt.id
  target_type = "ip"

  health_check {
    interval            = 30
    unhealthy_threshold = 5
  }
}

resource "aws_lb_listener" "frontend_https" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.frontend.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener" "frontend_http_redirect" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${local.name}-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.execution.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "ashirt/frontend:${var.tag}"
      essential = true
      portMappings = [
        { containerPort = local.nginx_port }
      ]
      environment = [
        { name = "NGINX_PORT", value = tostring(local.nginx_port) },
        { name = "WEB_URL", value = local.server_url },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ashirt.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "frontend"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "frontend" {
  name            = "${local.name}-frontend"
  cluster         = aws_ecs_cluster.ashirt.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = var.min_frontend_instances
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.frontend_ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = local.nginx_port
  }

  depends_on = [aws_lb_listener.frontend_https]
}

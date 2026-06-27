resource "random_password" "session_key" {
  length  = 48
  special = false
}

# Internal load balancer fronting the ashirt-server tasks. The frontend and
# ocr-worker reach the API through this.
resource "aws_lb" "server" {
  name               = "${local.name}-server"
  internal           = true
  load_balancer_type = "application"
  subnets            = aws_subnet.private[*].id
  security_groups    = [aws_security_group.server_alb.id]

  tags = {
    Name = "${local.name}-server"
  }
}

resource "aws_lb_target_group" "server" {
  name        = "${local.name}-server"
  port        = local.app_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.ashirt.id
  target_type = "ip"

  health_check {
    matcher = "200,401,404"
  }
}

resource "aws_lb_listener" "server" {
  load_balancer_arn = aws_lb.server.arn
  port              = local.app_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.server.arn
  }
}

locals {
  server_url = "http://${aws_lb.server.dns_name}:${local.app_port}"

  ashirt_server_environment = concat(
    [
      { name = "STORE_TYPE", value = "s3" },
      { name = "STORE_BUCKET", value = aws_s3_bucket.ashirt_storage.bucket },
      { name = "STORE_REGION", value = var.region },
      { name = "APP_IMGSTORE_BUCKET_NAME", value = aws_s3_bucket.ashirt_storage.bucket },
      { name = "APP_IMGSTORE_REGION", value = var.region },
      { name = "APP_PORT", value = tostring(local.app_port) },
      { name = "APP_SESSION_STORE_KEY", value = random_password.session_key.result },
    ],
    [for k, v in var.ashirt_server_env : { name = k, value = v }],
  )
}

resource "aws_ecs_task_definition" "ashirt_server" {
  family                   = "${local.name}-server"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.ashirt_server.arn

  container_definitions = jsonencode([
    {
      name      = "ashirt-server"
      image     = "ashirt/ashirt-server:${var.tag}"
      essential = true
      portMappings = [
        { containerPort = local.app_port }
      ]
      environment = local.ashirt_server_environment
      secrets = [
        { name = "DB_URI", valueFrom = aws_secretsmanager_secret.dsn.arn }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ashirt.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ashirt-server"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "ashirt_server" {
  name            = "${local.name}-server"
  cluster         = aws_ecs_cluster.ashirt.id
  task_definition = aws_ecs_task_definition.ashirt_server.arn
  desired_count   = var.min_ashirt_server_instances
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.server_ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.server.arn
    container_name   = "ashirt-server"
    container_port   = local.app_port
  }

  depends_on = [
    aws_lb_listener.server,
    null_resource.migrate,
  ]
}

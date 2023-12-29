# Cluster and logging

resource "aws_ecs_cluster" "ashirt" {
  name = var.app_name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "logs" {
  name              = "/fargate/service/${var.app_name}"
  retention_in_days = 90
}

# Web service (backend service for nginx frontend)

resource "aws_ecs_service" "ashirt-web" {
  name            = "${var.app_name}-web"
  depends_on      = [null_resource.ecs-run-task-init]
  cluster         = aws_ecs_cluster.ashirt.id
  task_definition = aws_ecs_task_definition.web.arn
  desired_count   = var.web_count
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.web.arn
    container_name   = "${var.app_name}-web"
    container_port   = var.app_port
  }

  dynamic "load_balancer" {
    for_each = var.debug_mode ? ["true"] : []
    content {
      target_group_arn = aws_lb_target_group.debug[0].arn
      container_name   = "${var.app_name}-web"
      container_port   = var.debug_port
    }
  }

  network_configuration {
    security_groups  = var.debug_mode ? [aws_security_group.debug.0.id, "${aws_security_group.web-ecs.id}"] : ["${aws_security_group.web-ecs.id}"]
    subnets          = var.private_subnet ? aws_subnet.private.*.id : aws_subnet.public.*.id
    assign_public_ip = var.private_subnet ? false : true
  }
}

resource "aws_ecs_task_definition" "web" {
  family             = "${var.app_name}-web"
  execution_role_arn = aws_iam_role.web.arn
  task_role_arn      = aws_iam_role.web.arn
  container_definitions = jsonencode([
    {
      name      = "${var.app_name}-web"
      image     = "ashirt/web:${var.tag}"
      cpu       = var.cpu
      memory    = var.mem
      essential = true
      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
        },
        {
          containerPort = var.debug_port
          hostPort      = var.debug_port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/fargate/service/${var.app_name}"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
      environmentFiles = [
        {
          value = "${aws_s3_bucket.env.arn}/web/.env"
          type  = "s3"
        },
      ]
    }
  ])
  cpu          = var.cpu
  memory       = var.mem
  network_mode = "awsvpc"
  requires_compatibilities = [
    "FARGATE"
  ]
}

# Frontend service. Nginx serves static content and proxies to web service.

resource "aws_ecs_service" "ashirt-frontend" {
  name            = "${var.app_name}-frontend"
  cluster         = aws_ecs_cluster.ashirt.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = var.frontend_count
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "${var.app_name}-frontend"
    container_port   = var.nginx_port
  }

  network_configuration {
    security_groups  = ["${aws_security_group.frontend-ecs.id}"]
    subnets          = var.private_subnet ? aws_subnet.private.*.id : aws_subnet.public.*.id
    assign_public_ip = var.private_subnet ? false : true
  }
}

resource "aws_ecs_task_definition" "frontend" {
  family             = "${var.app_name}-frontend"
  execution_role_arn = aws_iam_role.web.arn
  task_role_arn      = aws_iam_role.web.arn
  container_definitions = jsonencode([
    {
      name      = "${var.app_name}-frontend"
      image     = "ashirt/frontend:${var.tag}"
      cpu       = var.cpu
      memory    = var.mem
      essential = true
      portMappings = [
        {
          containerPort = var.nginx_port
          hostPort      = var.nginx_port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/fargate/service/${var.app_name}"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
      environment = [
        {
          name  = "WEB_URL"
          value = "http://${aws_lb.web.dns_name}:${var.app_port}"
        },
        {
          name  = "NGINX_PORT"
          value = tostring(var.nginx_port)
        }
      ]
    }
  ])
  cpu          = var.cpu
  memory       = var.mem
  network_mode = "awsvpc"
  requires_compatibilities = [
    "FARGATE"
  ]
}

# DB init task. Runs once, and anytime you change the global tag to apply sql migrations.

resource "aws_ecs_task_definition" "init" {
  family             = "init"
  execution_role_arn = aws_iam_role.web.arn
  task_role_arn      = aws_iam_role.web.arn
  container_definitions = jsonencode([
    {
      name      = "${var.app_name}-init"
      image     = "ashirt/init:${var.tag}"
      cpu       = var.cpu
      memory    = var.mem
      essential = true
      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/fargate/service/${var.app_name}"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
      environmentFiles = [
        {
          value = "${aws_s3_bucket.env.arn}/web/.env"
          type  = "s3"
        }
      ]
    }
  ])
  cpu          = var.cpu
  memory       = var.mem
  network_mode = "awsvpc"
  requires_compatibilities = [
    "FARGATE"
  ]
}

resource "null_resource" "ecs-run-task-init" {
  provisioner "local-exec" {
    command = <<EOT
aws ecs run-task \
--task-definition ${aws_ecs_task_definition.init.arn} \
--cluster ${aws_ecs_cluster.ashirt.arn} \
--launch-type FARGATE \
--network-configuration 'awsvpcConfiguration={subnets=[${join(",", var.private_subnet ? aws_subnet.private.*.id : aws_subnet.public.*.id)}],securityGroups=[${aws_security_group.web-ecs.id}],assignPublicIp=${var.private_subnet ? "DISABLED" : "ENABLED"}}' \
--region ${var.region}
EOT
  }
  depends_on = [
    aws_rds_cluster.ashirt,
    aws_ecs_task_definition.init,
    aws_s3_object.webenv,
    aws_iam_role.web
  ]
  triggers = {
    version_database = join(",", [aws_rds_cluster.ashirt.id, var.tag])
  }
}

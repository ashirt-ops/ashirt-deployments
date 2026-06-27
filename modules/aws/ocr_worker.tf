resource "aws_secretsmanager_secret" "ocr_worker_access_key" {
  name = "${local.name}-ocr-worker-access-key"
}

resource "aws_secretsmanager_secret_version" "ocr_worker_access_key" {
  secret_id     = aws_secretsmanager_secret.ocr_worker_access_key.id
  secret_string = var.ocr_worker_access_key
}

resource "aws_secretsmanager_secret" "ocr_worker_secret_key" {
  name = "${local.name}-ocr-worker-secret-key"
}

resource "aws_secretsmanager_secret_version" "ocr_worker_secret_key" {
  secret_id     = aws_secretsmanager_secret.ocr_worker_secret_key.id
  secret_string = var.ocr_worker_secret_key
}

locals {
  ocr_worker_environment = concat(
    [
      { name = "API_BASE", value = local.server_url },
    ],
    [for k, v in var.ocr_worker_env : { name = k, value = v }],
  )
}

resource "aws_ecs_task_definition" "ocr_worker" {
  family                   = "${local.name}-ocr-worker"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.ocr_worker_cpu
  memory                   = var.ocr_worker_memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.ocr_worker.arn

  container_definitions = jsonencode([
    {
      name        = "ocr-worker"
      image       = "ashirt/ocr-worker:${var.ocr_worker_tag}"
      essential   = true
      environment = local.ocr_worker_environment
      secrets = [
        { name = "ACCESS_KEY", valueFrom = aws_secretsmanager_secret.ocr_worker_access_key.arn },
        { name = "SECRET_KEY", valueFrom = aws_secretsmanager_secret.ocr_worker_secret_key.arn },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ashirt.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ocr-worker"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "ocr_worker" {
  name            = "${local.name}-ocr-worker"
  cluster         = aws_ecs_cluster.ashirt.id
  task_definition = aws_ecs_task_definition.ocr_worker.arn
  desired_count   = var.min_ocr_worker_instances
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ocr_worker_ecs.id]
    assign_public_ip = false
  }

  depends_on = [aws_ecs_service.ashirt_server]
}

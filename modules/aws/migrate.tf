# Database initialization / migration task. Runs once on first apply and again
# whenever var.tag changes, applying any pending SQL migrations before the
# ashirt-server service is (re)deployed.
resource "aws_ecs_task_definition" "init" {
  family                   = "${local.name}-init"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.ashirt_server.arn

  container_definitions = jsonencode([
    {
      name      = "init"
      image     = "ashirt/init:${var.tag}"
      essential = true
      secrets = [
        { name = "DB_URI", valueFrom = aws_secretsmanager_secret.dsn.arn }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ashirt.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "init"
        }
      }
    }
  ])
}

resource "null_resource" "migrate" {
  triggers = {
    cluster = aws_ecs_cluster.ashirt.id
    tag     = var.tag
  }

  provisioner "local-exec" {
    interpreter = ["/bin/sh", "-c"]
    command     = <<-EOT
      set -e
      TASK_ARN=$(aws ecs run-task \
        --task-definition ${aws_ecs_task_definition.init.arn} \
        --cluster ${aws_ecs_cluster.ashirt.arn} \
        --launch-type FARGATE \
        --network-configuration 'awsvpcConfiguration={subnets=[${join(",", aws_subnet.private[*].id)}],securityGroups=[${aws_security_group.server_ecs.id}],assignPublicIp=DISABLED}' \
        --region ${var.region} \
        --query 'tasks[0].taskArn' --output text)
      echo "Started init task $TASK_ARN; waiting for it to complete..."
      aws ecs wait tasks-stopped --cluster ${aws_ecs_cluster.ashirt.arn} --tasks "$TASK_ARN" --region ${var.region}
    EOT
  }

  depends_on = [
    aws_rds_cluster_instance.ashirt,
    aws_secretsmanager_secret_version.dsn,
    aws_ecs_task_definition.init,
    aws_iam_role_policy.execution_secrets,
    aws_nat_gateway.nat,
  ]
}

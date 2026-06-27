resource "aws_ecs_cluster" "ashirt" {
  name = local.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "ashirt" {
  name              = "/ecs/${local.name}"
  retention_in_days = var.log_retention_in_days
}

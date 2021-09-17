# RDS Cluster and subnet group

resource "aws_rds_cluster" "ashirt" {
  cluster_identifier        = "ashirt"
  engine                    = "aurora-mysql"
  database_name             = "ashirt"
  master_username           = "ashirt"
  master_password           = var.db_password
  backup_retention_period   = 5
  preferred_backup_window   = "07:00-09:00"
  engine_mode               = "serverless"
  vpc_security_group_ids    = [aws_security_group.rds.id]
  db_subnet_group_name      = aws_db_subnet_group.default.name
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.app_name}-${formatdate("YYYY-MM-DD-hh-mm", timestamp())}"
  scaling_configuration {
    min_capacity = 1
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "${var.app_name}-main"
  subnet_ids = aws_subnet.public.*.id
}

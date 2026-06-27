resource "random_password" "db_password" {
  length  = 24
  special = false
}

resource "aws_db_subnet_group" "ashirt" {
  name       = local.name
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = local.name
  }
}

# Aurora MySQL (Serverless v2). storage_encrypted defaults to the AWS-managed
# aws/rds key when kms_key_id is omitted, so no customer-managed key is used.
resource "aws_rds_cluster" "ashirt" {
  cluster_identifier      = local.name
  engine                  = "aurora-mysql"
  engine_mode             = "provisioned"
  database_name           = "ashirt"
  master_username         = "ashirt"
  master_password         = random_password.db_password.result
  db_subnet_group_name    = aws_db_subnet_group.ashirt.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  storage_encrypted       = true
  backup_retention_period = 7
  preferred_backup_window = "07:00-09:00"
  skip_final_snapshot     = true
  deletion_protection     = false

  serverlessv2_scaling_configuration {
    min_capacity = var.rds_min_capacity
    max_capacity = var.rds_max_capacity
  }
}

resource "aws_rds_cluster_instance" "ashirt" {
  identifier           = "${local.name}-1"
  cluster_identifier   = aws_rds_cluster.ashirt.id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.ashirt.engine
  engine_version       = aws_rds_cluster.ashirt.engine_version
  db_subnet_group_name = aws_db_subnet_group.ashirt.name
}

# The DSN is stored in Secrets Manager and injected into the ashirt-server and
# init tasks. The default secret uses the AWS-managed aws/secretsmanager key.
resource "aws_secretsmanager_secret" "dsn" {
  name = "${local.name}-dsn"
}

resource "aws_secretsmanager_secret_version" "dsn" {
  secret_id     = aws_secretsmanager_secret.dsn.id
  secret_string = "ashirt:${random_password.db_password.result}@tcp(${aws_rds_cluster.ashirt.endpoint}:3306)/ashirt"
}

# Daily s3 and RDS backups for 35 days
resource "aws_backup_vault" "ashirt" {
  name        = "ashirt"
  kms_key_arn = var.kms ? aws_kms_key.ashirt.0.arn : ""
}

resource "aws_backup_plan" "backup" {
  name = "ashirt"

  rule {
    rule_name         = "ashirt_backups_rule"
    target_vault_name = aws_backup_vault.ashirt.name
    schedule          = "cron(0 5 ? * * *)"
    lifecycle {
      delete_after = 35
    }
  }
}

resource "aws_iam_role" "backup" {
  name               = "backup"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["sts:AssumeRole"],
      "Effect": "allow",
      "Principal": {
        "Service": ["backup.amazonaws.com"]
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "backup" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup.name
}

resource "aws_backup_selection" "backup" {
  iam_role_arn = aws_iam_role.backup.arn
  name         = "ashirt"
  plan_id      = aws_backup_plan.backup.id

  resources = [
    aws_s3_bucket.data.arn,
    aws_s3_bucket.env.arn,
    aws_rds_cluster.ashirt.arn
  ]
}
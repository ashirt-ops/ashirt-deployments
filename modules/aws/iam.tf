data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Execution role: shared by every task definition. Pulls images, writes logs,
# and fetches the secrets injected into containers.
resource "aws_iam_role" "execution" {
  name               = "${local.name}-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# The default aws/secretsmanager managed key handles decryption, so only
# GetSecretValue is required to inject the secrets at task start.
data "aws_iam_policy_document" "execution_secrets" {
  statement {
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      aws_secretsmanager_secret.dsn.arn,
      aws_secretsmanager_secret.ocr_worker_access_key.arn,
      aws_secretsmanager_secret.ocr_worker_secret_key.arn,
    ]
  }
}

resource "aws_iam_role_policy" "execution_secrets" {
  name   = "${local.name}-execution-secrets"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.execution_secrets.json
}

# Task role for ashirt-server: read/write evidence in the storage bucket.
resource "aws_iam_role" "ashirt_server" {
  name               = "${local.name}-server"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

data "aws_iam_policy_document" "ashirt_server_storage" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
    ]
    resources = ["${aws_s3_bucket.ashirt_storage.arn}/*"]
  }

  statement {
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [aws_s3_bucket.ashirt_storage.arn]
  }
}

resource "aws_iam_role_policy" "ashirt_server_storage" {
  name   = "${local.name}-server-storage"
  role   = aws_iam_role.ashirt_server.id
  policy = data.aws_iam_policy_document.ashirt_server_storage.json
}

# Task role for ocr-worker: AWS Textract for the "aws" OCR backend.
resource "aws_iam_role" "ocr_worker" {
  name               = "${local.name}-ocr-worker"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

data "aws_iam_policy_document" "ocr_worker" {
  statement {
    actions = [
      "textract:DetectDocumentText",
      "textract:AnalyzeDocument",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ocr_worker" {
  name   = "${local.name}-ocr-worker"
  role   = aws_iam_role.ocr_worker.id
  policy = data.aws_iam_policy_document.ocr_worker.json
}

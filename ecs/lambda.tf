locals {
  prefix              = "ashirt-workers"
  account_id          = data.aws_caller_identity.current.account_id
  ecr_repository_name = "${local.prefix}-ocr"
  ecr_image_tag       = "latest"
}

resource "aws_ecr_repository" "repo" {
  name = local.ecr_repository_name
  image_scanning_configuration {
    scan_on_push = true
  }
}

# Pull the latest demo-ocr image and re-upload to ECR registry (required for container lambda)
resource "null_resource" "ocr_image" {
  provisioner "local-exec" {
    command = <<EOF
           aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${local.account_id}.dkr.ecr.${var.region}.amazonaws.com
           docker pull ashirt/demo-ocr:latest
           docker tag ashirt/demo-ocr:latest ${aws_ecr_repository.repo.repository_url}:${local.ecr_image_tag}
           docker push ${aws_ecr_repository.repo.repository_url}:${local.ecr_image_tag}
       EOF
  }
}

data "aws_ecr_image" "ocr_image" {
  depends_on = [
    null_resource.ocr_image
  ]
  repository_name = local.ecr_repository_name
  image_tag       = local.ecr_image_tag
}

resource "aws_iam_role" "lambda" {
  name               = "${local.prefix}-lambda-role"
  assume_role_policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
       {
           "Action": "sts:AssumeRole",
           "Principal": {
               "Service": "lambda.amazonaws.com"
           },
           "Effect": "Allow"
       }
   ]
}
 EOF
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["*"]
    sid       = "CreateCloudWatchLogs"
  }
}

resource "aws_iam_policy" "lambda" {
  name   = "${local.prefix}-lambda-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_iam_role_policy_attachment" "LambdaExecutionRole-ocr" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

# Update the keys in variables.tf and re-apply after setting up a headless user in the application
# Hopefully this can be automated in the future
resource "aws_lambda_function" "ocr" {
  depends_on = [
    null_resource.ocr_image
  ]
  function_name = "${local.prefix}-ocr"
  role          = aws_iam_role.lambda.arn
  timeout       = 60
  image_uri     = "${aws_ecr_repository.repo.repository_url}@${data.aws_ecr_image.ocr_image.id}"
  package_type  = "Image"
  memory_size   = 256
  environment {
    variables = {
      ASHIRT_ACCESS_KEY   = var.worker_access_key,
      ASHIRT_BACKEND_PORT = "443",
      ASHIRT_BACKEND_URL  = aws_route53_record.api.name,
      ASHIRT_SECRET_KEY   = var.worker_secret_key
    }
  }
}

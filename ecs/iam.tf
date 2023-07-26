# Allow ECS to assume our roles

data "aws_iam_policy_document" "assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# IAM Roles
resource "aws_iam_role" "web" {
  name               = "${var.app_name}-web"
  path               = "/system/"
  assume_role_policy = data.aws_iam_policy_document.assume-role-policy.json
}

# Attach ECSTaskExecutionRolePolicy. Allows the container to send logs.
resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole-web" {
  role       = aws_iam_role.web.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecsLambdaExecutionRole-web" {
  role       = aws_iam_role.web.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}

# Give nginx and the web service access to environment variable files

resource "aws_iam_policy" "webenv" {
  name        = "${var.app_name}-webenv-policy"
  path        = "/"
  description = ".env.web policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject"
        ],
        Resource = [
          "${aws_s3_bucket.env.arn}/web/.env",
          "${aws_s3_bucket.env.arn}/db/.env",
          "${aws_s3_bucket.env.arn}/app/.env"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetBucketLocation"
        ],
        Resource = [
          aws_s3_bucket.env.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "env-web" {
  role       = aws_iam_role.web.name
  policy_arn = aws_iam_policy.webenv.arn
}

# Give web service full access to data bucket

resource "aws_iam_policy" "appdata" {
  name        = "${var.app_name}-appdata-policy"
  path        = "/"
  description = "appdata access policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion"
        ],
        Resource = [
          "${aws_s3_bucket.data.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "data-web" {
  role       = aws_iam_role.web.name
  policy_arn = aws_iam_policy.appdata.arn
}

# Give KMS Decrypt permissions

resource "aws_iam_policy" "appdatakms" {
  count       = var.kms ? 1 : 0
  name        = "${var.app_name}-appdatakms-policy"
  path        = "/"
  description = "appdata kms access policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ],
        Resource = [
          "${aws_kms_key.ashirt[count.index].arn}"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "kms-web" {
  count      = var.kms ? 1 : 0
  role       = aws_iam_role.web.name
  policy_arn = aws_iam_policy.appdatakms[count.index].arn
}

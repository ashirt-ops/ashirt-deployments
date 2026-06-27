# AWS (ECS Fargate) reference deployment

An opinionated, serverless reference deployment of ASHIRT on AWS, mirroring the
[GCP module](../gcp). It runs the ASHIRT services on ECS Fargate behind
Application Load Balancers, backed by an Aurora MySQL (Serverless v2) cluster and
an S3 evidence bucket.

## Architecture

- **ashirt-server** — the API/backend, on ECS Fargate behind an *internal* ALB.
- **frontend** — the nginx frontend, on ECS Fargate behind a *public* HTTPS ALB.
  It proxies API traffic to the internal ashirt-server ALB.
- **ocr-worker** — an ECS Fargate service that polls the ashirt-server API and
  performs OCR. Outbound only; no inbound load balancer.
- **init** — a one-shot ECS task that applies database migrations. It runs on
  first apply and again whenever `tag` changes, before ashirt-server is
  (re)deployed.
- **Aurora MySQL Serverless v2** — the database. The DSN is stored in AWS Secrets
  Manager and injected into the server/init tasks.
- **S3** — evidence storage.
- **VPC** — public subnets (frontend ALB + a single NAT gateway) and private
  subnets (ECS tasks, internal ALB, Aurora) across `az_count` availability zones.

### Encryption

All encryption uses Amazon-managed keys — no customer-managed KMS keys are
created or required:

- S3: SSE-S3 (AES256).
- Aurora: `storage_encrypted = true` with the AWS-managed `aws/rds` key.
- Secrets Manager: the AWS-managed `aws/secretsmanager` key.

## Requirements

- Terraform >= 1.5.0
- AWS credentials with permission to create the resources above
- The AWS CLI on the machine running `terraform apply` (used to run the database
  migration task)
- A **Route53 public hosted zone** for `var.domain` that already exists. The
  module looks it up, requests an ACM certificate for `var.frontend_domain`,
  validates it via DNS, and creates the alias record.

## Usage

This module is consumed through [`examples/aws`](../../examples/aws). See the
repository [README](../../README.md) for the submodule/symlink workflow. At a
minimum set `domain`, `frontend_domain`, `tag`, and `ocr_worker_tag` in your
`locals.tf`.

```sh
terraform init
terraform apply
```

The `frontend_url` output is the address to browse to once the ACM certificate
validates and the services become healthy.

## Initial login

The example `ashirt_server_env` enables ASHIRT local authentication with
registration so you can create the first admin user. After registering your
initial users, remove `AUTH_SERVICES_ALLOW_REGISTRATION` from
`ashirt_server_env` and re-apply.

## OCR service worker

After logging in as an admin, create a headless user with API keys, set
`ocr_worker_access_key` / `ocr_worker_secret_key` in your `locals.tf`, and
re-apply. Configure the service worker in the ASHIRT admin UI to match the
deployed `ocr-worker`. `BACKEND` (set via `ocr_worker_env`) selects the OCR
engine; the default example uses `aws` (Amazon Textract), for which the
ocr-worker task role is granted Textract permissions.

# ECS Deployment
A serverless deployment of ashirt-server.

# Requirements

Latest version of terraform

```sh
brew install terraform
```

Register a domain in Route53 through the AWS console.

# Must Update

Review `variables.tf` for mandatory and optional changes.

Review `.env.web` and configure as desired per https://github.com/theparanoids/ashirt-server/wiki/backendconfig

# Init

```sh
cd ecs/
terraform init
```

# Install

```sh
terraform apply --auto-approve
```

# Destroy ashirt

```sh
terraform destroy
```

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

# Intial Login

The provided configuration enables registration for ashirt local authentication to allow the setup of an initial admin user in new production deployments. After the first users are registered the admin should change `AUTH_SERVICES_ALLOW_REGISTRATION=ashirt` to `AUTH_SERVICES_ALLOW_REGISTRATION=` in `.env.web` and re-deploy by running
```sh
terraform apply --auto-approve
```

# Service Workers Setup

After deploying the application and registering your first admin user, you can create a headless user account with API keys. Those API keys can be added to variables.tf (or injected via a more secure method). The lambda is updated by again running
```sh
terraform apply --auto-approve
```

Under the admin page setup a service worker with the below configuration:

```
{
  "type": "aws",
  "version": 1,
  "lambdaName": "ashirt-workers-ocr",
  "asyncFunction": false
}
```

The lambda will now invoke for new pieces of image evidence. To process existing evidence you can run a worker on multiple items from the operation admin settings. 
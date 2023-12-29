# ECS Deployment
A serverless deployment of ashirt-server.

# Requirements

Latest version of terraform

```sh
brew install terraform
```

Latest version of Docker Desktop https://docs.docker.com/desktop/install

Register a domain in Route53 through the AWS console, or have a pre-existing domain in route53.

# Must Update

Review `variables.tf` for mandatory and optional changes. You will need to add a base domain name e.g. `mydomain.com` and choose names for two new s3 buckets. 

Review `appconfig.tf` and configure as desired per https://github.com/theparanoids/ashirt-server/wiki/backendconfig. No changes are required for a simple deployment with local authetication.

# Init

```sh
cd ecs/
terraform init
```

# Install

```sh
terraform apply --auto-approve
```

# Intial Login

The provided configuration enables registration for ashirt local authentication to allow the setup of an initial admin user in new production deployments. After the first users are registered the admin should change `AUTH_SERVICES_ALLOW_REGISTRATION=ashirt` to `#AUTH_SERVICES_ALLOW_REGISTRATION=ashirt` in `.env.web` and re-deploy by running:
```sh
terraform apply --auto-approve
```

# Service Workers Setup

After deploying the application, registering, and logging in with your first admin user you can create a new headless user account with API keys. Those API keys can be added to variables.tf (or injected via a more secure method). The lambda is updated by again running:
```sh
terraform apply --auto-approve
```

In the ashirt admin page setup a service worker with the below configuration.

```
{
  "type": "aws",
  "version": 1,
  "lambdaName": "ashirt-workers-ocr",
  "asyncFunction": false
}
```

The lambda will now invoke for new pieces of image evidence. To process existing evidence you can run a worker on multiple items from the operation admin settings. 


# Manage Ashirt

If you need to interact with the database set `maintenance_mode` to `true` to provision a bastion with network access to the RDS instance.

To debug a production instance set `debug_mode` to `true` to provision network access to the `debug_port`. This should normally be used in conjunction with `maintenance_mode`. To disable `debug_mode` properly you may need to re-create the web service.

```sh
terraform apply -var-file vars.tfvars -replace aws_ecs_service.ashirt-web --auto-approve
```

# Uninstall Ashirt

```sh
terraform destroy
```
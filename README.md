# ashirt-deployments

⚠️ **Under Construction** ⚠️

**NOTE:** This repository is currently being rewritten to support new recommended deployment schemes that should be ideal for most uses. The GCP version is ready for testing with some additional changes planned, the AWS one will be updated shortly.

Terraform configurations for deploying ASHIRT

## Design Choices

This repository provides opinionated default production deployment configurations for a serverless deployment in AWS (ECS Fargate) and GCP (Cloud Run). These configurations are intended to provide an affordable semi-fault tolerant deployment for use by a realtively small team. If you need higher availability or larger scale, you can adjust the tier sizing or deploy into a more advanced environment. If you would like to to deploy into another environment, such as k8s, that is an exercise left to the reader.

This architecture was built with the following goals:
- Single region
- Single AZ
- No blue/green deployments
- Managed and encrypted at rest storage for evidence
- Managed SQL server
- Serverless deployments on AWS or GCP

## How to use this repository

1. Choose your cloud (AWS or GCP)
2. Create a new repository in your version control system (needs to be git)
3. Create a git submodule of this repo into your repo
4. Create a symlink for `examples/<cloud>/main.tf` and `examples/<cloud>/outputs.tf` to your repo
5. Copy `examples/<cloud>/locals.tf` into your repo

All configuration options will be versioned and configured through the `locals.tf` file. You should periodically check for updates to the [ashirt-deployments](https://www.github.com/ashirt-ops/ashirt-deployments) repo and update the submodule as needed to ensure that you are deploying with templates that match the appropriate version of ASHIRT.

## Where is the state stored

Terraform expects to store state somewhere. This is a decision you'll need to make. The most simple decision is to store it in your repo along side your `locals.tf`. You can version it within git. This is ideal if you're not using CI/CD to automatically deploy the environment from the repository. You can also set up the deployment to use remote backends. You can view the instructions [here](https://developer.hashicorp.com/terraform/language/backend) to configure a remote backend that fits your needs.

## How to managed multiple environments

If you want to create a staging and production environment for rolling out new versions, consider creating a staging branch and using the main branch to map to production. Each branch can have it's own copy of the `locals.tf` file that adjusts the configuration appropriately. This can be used with or without CI/CD for automated deployments.


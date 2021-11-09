# EKS Setup - ashirt

## Setup Environment

Before starting you'll need to following pre-requisites:

1. awscli (homebrew)
1. kubectl (homebrew)
1. helm (homebrew)
1. [sql-migrate](https://github.com/rubenv/sql-migrate)

## Prerequisites

These are instructions assume you already have:
- An AWS account
- EKS cluster already provisioned
- A public domain in route53
- ACM certificates for this domain

The above can be created in the AWS console, or your automation tool of choice. In this doc `EKS` and `k8s` may be used interchangeably to refer to this EKS deployment. This acts as a base deployment, and does not cover common requirements such as CKMS, load balander logging, etc.

### Infrastructure Setup

Create s3 bucket {{EVIDENCE_BUCKET_NAME}} (ensure encryption and logging is setup)
Create an IAM role named `ashirt-k8s-s3` with the following policy:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::{{EVIDENCE_BUCKET_NAME}}/*"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "s3:HeadBucket",
            "Resource": "arn:aws:s3:::{{EVIDENCE_BUCKET_NAME}}/*"
        }
    ]
}
```

Reference the name of your EKS node instance role in ec2.
Edit the trust relationships for this policy and add the following with your node instance role:

```
{
  "Sid": "",
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::{{ACCOUNT_NUMBER}}:role/<eks_node_role>"
  },
  "Action": "sts:AssumeRole"
}
```

In your EKS node instance role for your ec2, attach a policy which allows the node to assume any policies starting with ashirt-k8s-*.
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:iam::{{ACCOUNT_NUMBER}}:role/ashirt-k8s-*"
            ],
            "Action": "sts:AssumeRole"
        }
    ]
}
```

### Database Creation

Now we have to setup the ashirt [database](https://us-west-2.console.aws.amazon.com/rds/home?region=us-west-2#launch-dbinstance:gdb=false;s3-import=false), this is done manually but requires minimal clicking. Ensure to change the default options for the following:
- Choose Aurora, Mysql 5.7 (serverless or provisioned)
- Db cluster identifier as ashirt
- Autogenerate password, instance size t3.medium and choose the rds sg
- In Additional options choose the encryption key you created.
Make note of the autogen credentials...(db creation takes some time, continue with other setup - confirm before deploying the ashirt cluster)
- Create a new Security group which only allows 3306 traffic from your VPC CIDR


### Setup DB Schema

This is currently a manual step that requires setting up an SSH tunnel to connect to the RDS instance and load the schema into the database. The schema file referenced below can be found in the ASHIRT repository in `backend/schema.sql`.

```sh
mysql -h {{RDS_HOST}}.us-west-2.compute.amazonaws.com -u <username> -p <password> -D ashirt < schema.sql
```

### Setup Calico

Install calico which is a network policy engine for amazon's EKS.This is needed later for allowing/denying traffic to certain pods etc.
`kubectl apply -f https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/master/config/v1.6/calico.yaml`

### Install Application

```sh
helm install ashirt . -f <values file for environment> --set "tag=<git short commit>"
```

### Add Secrets

Adding secrets must be done after installing the application so that the namespaces will exist. All of the non-secret configuration values will already be present from the installation.

```sh
./gen_secrets.sh
```

### Setup ELB

This is currently a manual step but should be automated in the future. The zone file in Route53 needs to be updated to point the DNS entries at the load balancers that have been created during the helm install process. You can use kubectl to get the values to use. This may take a few minutes for DNS changes to propagate.

```sh
kubectl get svc --all-namespaces
```

Take the two entries with type LoadBalancer (frontend-lb and public-lb) and add the value for external ip to the DNS entrys for your domains as required.

## Maintainence

### Updating ASHIRT

Updating ASHIRT generally will consist of simply changing the running image to a new one. For updates that require database changes you'll need to run the mgirations 

#### Running Migrations

Migrations are performed using the sql-migrate tool that can migrate and revert db changes. Once installed this should be run from the root of the ashirt repo.

```sh
sql-migrate up -config=backend/dbconfig.yml
```

#### Upgrade Containers/Demployment

```sh
helm upgrade ashirt . -f <values file for environment> --set "tag=<git short id>"
```

### Reverting a Bad Updgrade

#### Migrate Down any Database Changes

```sh
sql-migrate down -limit=<number of migrations to undo> -config=backend/dbconfig.yml
```

#### Revert Containers/Deployment

```sh
helm upgrade ashirt . -f <values file for environment> --set "tag=<git short id>"
```

### Scale your deployment to 6 pods
Current pods is 3, suppose you starting hacking the planet and pulling the stager from the builder becomes a bottleneck run this 

`kubectl scale --replicas=6 deployment/ashirt-frontend`

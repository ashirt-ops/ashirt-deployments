# EKS Setup - ashirt

## Setup Environment

Before starting you'll need to following pre-requisites:

1. awscli (homebrew)
1. kubectl (homebrew)
1. helm (homebrew)
1. [sql-migrate](https://github.com/rubenv/sql-migrate)

## Fresh Start

These are instructions for deploying ASHIRT from an empty AWS account. If you are re-installing make sure to clean up any exisiting infrastructure in the eks cluster that may conflict.

### Infrastructure Setup

Login to your aws console and go [here](https://us-west-2.console.aws.amazon.com/ec2/home?region=us-west-2#Images:visibility=public-images;source=amazon/amazon-eks-node;ownerAlias=amazon;creationDate=%3E2019-09-01T00:00-07:00;sort=desc:creation_date). This should list the latest amis for the EKS nodes published by aws. Choose the latest version and copy ami to us-west-2 region with " Encrypt target EBS snapshots" enabled. take note of the new ami-id.

*NOTE - this doc uses ashirt for cluster names. Make sure to substitude for apant where applicable (eks, rds, s3, iam, etc.)

- Create a new Security group which only allows 3306 traffic from 192.168.0.0/16 (VPC Ips) (Keep a note of this)
- Also create a new [Encryption](https://us-west-2.console.aws.amazon.com/kms/home?region=us-west-2#/kms/keys) key and set it to "auto rotate" also. Grant key usage to your k8s node group. Once you have roles setup for s3 usage etc make sure to add those roles here too.

Create s3 bucket {{EVIDENCE_BUCKET_NAME}} (ensure encryption and logging is setup) *TODO: automate?*
Create a role named ashirt-k8s-s3 with the following policy:

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

Also in your node instance role for your ec2, it should be named something like ashirt-nodegroup..., attach a policy which allows the node to assume any policies starting with ashirt-k8s-*.
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:iam::{{ARN}}:role/ashirt-k8s-*"
            ],
            "Action": "sts:AssumeRole"
        }
    ]
}
```

The above roles were created so that ashirt can assume roles required in relation with kube2iam.

Now we have to setup the ashirt [database](https://us-west-2.console.aws.amazon.com/rds/home?region=us-west-2#launch-dbinstance:gdb=false;s3-import=false), this is done manually but requires minimal clicking. Ensure to change the default options for the following:
- Choose Aurora, Mysql 5.6.10a.
- Db cluster identifier as ashirt
- Autogenerate password, instance size t3.medium and choose the rds sg
- In Additional options choose the encryption key you created.
Make note of the autogen credentials...(db creation takes some time, continue with other setup - confirm before deploying the ashirt cluster)


*Anything below assumes you created an eks cluster in us-west-2 and have also uploaded the relevant SSL certs in AWS ACM plus you have the right arns for those certs + own a domain.*

Install calico which is a network policy engine for amazon's EKS.This is needed later for allowing/denying traffic to certain pods etc.
`kubectl apply -f https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/master/config/v1.5/calico.yaml`

### Setup DB Schema

This is currently a manual step that requires setting up an SSH tunnel to connect to the RDS instance and load the schema into the database. The schema file referenced below can be found in the ASHIRT repository in `backend/schema.sql`.

```sh
mysql -h {{RDS_HOST}}.us-west-2.compute.amazonaws.com -u <username> -p <password> -D ashirt < schema.sql
```

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

### Switching Clusters

The following can be used to update your k8s config to switch clusters between ashirt and apant or if you have the docker app installed can switch via the Kubernetes entry in the dropdown menu.

```
aws eks update-kubeconfig --name <cluster_name>
```

### Scale your deployment to 6 pods
Current pods is 3, suppose you starting hacking the planet and pulling the stager from the builder becomes a bottleneck run this 

`kubectl scale --replicas=6 deployment/ashirt-frontend`

### Other

#### KMS

To ensure KMS CMK is used for volumes when you create a new nodegroup, update eks/ashirt.yaml with your KMS key ID before deployment.

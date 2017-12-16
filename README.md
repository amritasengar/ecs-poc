# ECS Cluster PoC

## Background
We want to dockerise and deploy **hello_world.py** to Amazon Web Services with their Elastic Container Service, we want a secure isolated environment and we want to run multiple containers on an instance.

## Outcome
A Docker container running our Flask service in AWS ECS, autoscaled, secure, and stable.

## Prerequisites
The Terraform Amazon provider requires a working Access and Secret key in order to make calls to the AWS APIs and create/delete resources. The user associated with these keys should have sufficient rights to create/delete a wide variety of resources, e.g. 'admin' rights.

Terraform is capable of creating SSH keypairs within AWS. It falls over when it comes to downloading them to a usable location on your local workstation. We've kept this out of our terraform code, so you'll have to do this work ahead of time.

In the AWS console we created a keypair called 'eHA'. The private half of that keypair was downloaded to our local `.ssh` dir at `~/.ssh/eHa.pem` -- the exact path can be seen in [variables.tf](). This can also be done via `aws-cli` like so:
```
$ aws ec2 create-key-pair --key-name eHa
{
    "KeyMaterial": "-----BEGIN RSA PRIVATE KEY-----\nMII
    ...
    ...",
    "KeyName": "eHa",
    "KeyFingerprint": "ab:cd:ef:12:34:56:78:90"
}
```
The value in `KeyMaterial` will need to be copied to `~/.ssh/eHa.pem` and the `\n` strings replaced with actual newline characters.

We've included a dummy `terraform.tfvars.keep` file for your use. Copy this to `terraform.tfvars`, fill in the AWS keys, path to your SSH private key (`*.pem` file), and the name of that keypair in the AWS console.
```terraform.tfvars.keep
aws_access_key = "AKIAIMAMBLAHBLAHBLAH"
aws_secret_key = "g1bB3r1$hg1bB3r1$hg1bB3r1$hg1bB3r1$hg1bB3r1$h"
aws_key_path = "/home/username/.ssh/eHa.pem"
aws_key_name = "eHa"
```

We'll assume your workstation is capable of running `make` and have included a Makefile for ease of use.

## Principles
It hardly makes sense to re-invent the wheel when it comes to infrastructure code. Plenty of smart people have walked this path before us, so let's vet and then make use of their code. Reusing code, open-sourcing components, and understanding feedback from a well-meaning community of users strengthens our code. In short, we believe in theprinciple of 'share and share alike'.
Some of the blogs and projects we made use of in this coding challenge include Terraform/Hashicorp resources as well as the following:
 - https://blog.meshstudio.io/automating-ecs-deployments-with-terraform-1146736b7688
 - https://github.com/azavea/terraform-aws-ecs-cluster/blob/develop/main.tf
 - https://github.com/unifio/terraform-aws-ecs
 - https://github.com/Capgemini/terraform-amazon-ecs

We'll seek to apply the AWS Well-Architected framework principles where applicable in this solution.

In order to meet the principle of Security, we'll only allow access to the system and AWS resources on a least-privilege basis. IAM roles were used to limit the capabilities of certain AWS resources in this infrastructure. Should they misbehave, or should they be compromised, the blast radius is minimized.

For Reliability, Performance Efficiency, and Cost Optimization, we'll deploy our solution to an ECS cluster with an auto-scaling configuration attached. This will ensure that the cluster remains small enough to handle requests, self-heals in the face of error, is rarely over-provisioned and thus wasting capital, and at the same time is performant in the face of heavy load.

We'll seek to write modular, well-documented code and deploy self-healing systems, thus meeting the Pillar of Operational Excellence. Code will be documented. AWS resources will be tagged, where appropriate and available.

While there are many competing theories on how best to use (or not use) Terraform in an agile, source-controlled, devops-y sort of way, we'll just ignore all that debate `*.tfstate` file to source control and being done with it. We're going to create and destroy this network, cluster, stack, etc. many times in the course of iterative development. The wild changes captured in the tfstate file will reflect this. Livestock not pets. Gaining resiliancy from disorder. etc.

A hefty dose of `terraform init` scattered around our Makefile should prevent any hiccups with providers not being available on your local workstation while working with this code.

## Steps to Complete
Our first task was to create an AWS account and keypair to be used in the completion of this project, as described in [Prerequisites](## Prerequisites).  Then we completed the following tasks:

 - laying out a VPC with the following characteristics:
  - both public and private subnets
  - spans both London AZs
  - internal/private DNS zone: `myorg.local.`
  - routes to the internet for public and private subnet resources

## Future Work
This solution is, admittedly, somewhat non-portable. Where expedient, certain values were hard-coded into Terraform where they could have been variables set at run-time. For location specific resources such as AZs and subnets, AMIs, and buckets, we use the London AWS region where possible. In the future, this project might be updated to allow for the ECS cluster to be deployed to any region.

Container farms require constant care and feeding. While many serverless and container orchestration tools and techniques remove operational complexity from running distributed services, they do so at the expense of hiding that complexity from admins and engineers.

How this cluster might be managed day-to-day is a topic for lengthy discussion and will require training and education of operations engineers. Improvements would most certainly be suggesting. Hopefully this code is reusable to the point where others find it easy enough to work with.

The cluster is missing plenty of componentry and tooling that would make the work of Ops easier - metrics, monitoring, distributed tracing, a deployment model and pipeline for new microservices and new infrastructure, a dev/staging environment for testing and experimentation, etc.

We'd like to use SSL in our solution but making use of ACM manually to issue a cert is rather at odds with the goal of this project to make a portable, automated, shareable solution.

AWS recently announced a service called Fargate that will do away with running an ASG, instances, etc. for running containers inside ECS. Currently, Terraform's AWS provider does not provide the primitives to work with Fargate. We expect that will change in the near future and will greatly simplify this code.

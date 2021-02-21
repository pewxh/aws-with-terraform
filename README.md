# AWS PROVISIONING USING TERRAFORM

![image](https://i.ibb.co/QKWsBjT/awsterra.jpg)

## Description

This repo contains some handpicked problems of cloud provisioning that can be solved using IaC tool Terraform.

## Getting Started

### Dependencies

- [Terraform CLI Installed](https://www.terraform.io/)
- [AWS CLI Configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html)

### Installing

- [Terraform CLI](https://www.terraform.io/downloads.html)
- [AWS CLI 2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)

### Executing program

- NOTE: Each Module is independent of the other
- Download the module/folder you want to work on (or clone the entire repo AYC)
- Inside Each Module Follow the below commands

```
terraform init
terraform validate
terraform apply --auto-approve
terraform destroy --auto-approve

```

- NOTE: Only the run the last command (destroy) after your work is done!

### Also check the following blogs/articles for better understanding

- [Launching a web server using AWS EBS and Github](https://www.linkedin.com/pulse/automated-website-deployment-using-aws-terraform-github-piyush-mehta)
- [Launching a web server using AWS EFS and Github](https://pewxh.medium.com/launching-web-server-using-aws-efs-terraform-and-github-77f1b561eefa)
- [Setting up a VPC infrastructure](https://pewxh.medium.com/vpc-infrastructure-using-terraform-9f4e9da456ef)
- [Setting up a VPC infrastructure along with NAT Gateway](https://pewxh.medium.com/vpc-infrastructure-using-terraform-along-with-nat-gateway-3da47459ecb)
- [Deploying Wordpress App on Kubernetes and AWS](https://pewxh.medium.com/yet-another-wordpress-a57cee4bd9e4)
- [Storing objects in a S3 bucket and using Cloudfront](https://www.linkedin.com/pulse/automated-website-deployment-using-aws-terraform-github-piyush-mehta)

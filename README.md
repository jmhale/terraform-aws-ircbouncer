# terraform-aws-ircbouncer

Terraform module to deploy a IRC bouncer (ZNC) on AWS

## Variables
| Variable Name | Type | Required |Description |
|---------------|-------------|-------------|-------------|
|`public_subnet_ids`|`list`|Yes|A list of subnets for the Autoscaling Group to use for launching instances. May be a single subnet, but it must be an element in a list.|
|`ssh_key_id`|`string`|Yes|A SSH public key ID to add to the VPN instance.|
|`vpc_id`|`string`|Yes|The VPC ID in which Terraform will launch the resources.|
|`ingress_security_group_id`|`string`|Yes|The ID of the Security Group to allow SSH access from.|
|`ami_id`|`string`|No. Defaults to Ubuntu 16.04 AMI in us-east-1|The AMI ID to use.|

## Usage

```
module "terraform-aws-ircbouncer" {
  source = "git@github.com:jmhale/terraform-aws-ircbouncer.git"
}

```

## Outputs
| Output Name | Description |
|---------------|-------------|
|`irc_eip`|The public IPv4 address of the AWS Elastic IP assigned to the instance.|


LICENSE: 3-clause BSD license.


---
Copyright © 2019, James Hale

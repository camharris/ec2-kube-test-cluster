## Ec2 Kube Test Cluster

This repository is a simple terraform module that is used to deploy an ephemeral
kubernetes cluster on an ec2 instance using [kind](https://kind.sigs.k8s.io/) 
and docker. The original idea was prompted by the this 
[article](https://dev.to/rusty_sys_dev/create-expose-test-kubernetes-cluster-on-ec2-with-kind-16c3) 
written by [rustysys-dev](https://github.com/rustysys-dev). This module uses [terraform-aws-ec2-instance module](https://github.com/terraform-aws-modules/terraform-aws-ec2-instance) 
and follows it's example patterns.

This terraform module will provision an ec2 instance with the architecture of arm64
in us-west-2 with the size of t4g.large with 100gb volume. At the time of writing this was the
cheapest solution I could find for a internet accessible kube cluster that met my needs. The
AWS calculations comes out to an estimated 40.73 USD per month. 


### How to use
1. ```
    terraform init
    ```
2. ```
    terraform apply
    var.key_name
    ssh key for ec2 instance

    Enter a value: default_aws_key

    var.server_name
    Name of ec2 instance

    Enter a value: kind-k8s-cluster-instance
    ```

This will attempt to create an ec2 instance in the default region of us-west-2 with the name `kind-k8s-cluster-instance` running Ubuntu 20.04 with the existing ssh key named `default_aws_key` 

##  Input 
| Name | Description | Optional | Default |
|------|-------------|----------|---------|
| server_name | Name of ec2 instance | N | None|
| instance_size |ec2 instance size | Y | t4g.large|
| drive_size | ebs volume size in GB | Y | 100 |
| region | AWS region | Y | us-west-2 |
| key_name | existing ssh key for ec2 instance | N | None |

## Output
| Name | Description | 
|------|-------------|
| ids  | List of instance IDs |
| public_dns | List of DNS names of instances |
| vpc_security_group_ids | List of vpc security groups |
| root_block_device_volume_ids | List of volume IDs of root block devices of instances |
| ebs_block_device_volume_ids | List of volume IDs of EBS block devices of instances |
| tags | List of tags |
| placement_group | List of placement groups |
| instance_id |EC2 instance ID |
| instance_public_dns | Public DNS name of the instance |
| credit_specification | Credit specification of EC2 instance (empty list for not t2 instance types) |
| metadata_options | Metadata options for the instance | 

### TODO
- Refine the outputs
- add a provision resource that can pull the kube_config into an output variable


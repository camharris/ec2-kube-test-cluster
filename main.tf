variable "server_name" {
  type = string
  description = "Name of ec2 instance"
}

variable "instance_size" {
    type = string
    description = "ec2 instance size"
    default = "t4g.large"
}

variable "drive_size" {
  type = number
  description = "ebs volume size"
  default = 100
}

variable "region" {
  type = string
  description = "AWS region to provision in"
  default = "us-west-2"
}

variable "key_name" {
  type = string
  description = "ssh key for ec2 instance"
}


provider "aws" {
    region = var.region
}

locals {
    user_data = file("userdata.sh")
}


data "aws_vpc" "default" {
    default = true
}

data "aws_subnet_ids" "all" {
    vpc_id = data.aws_vpc.default.id
}

module "security_group" {
    source = "terraform-aws-modules/security-group/aws"
    version = "~> 4.0"
    
    name        = "kind-dev-node"
    description = "Security group for ec2 instance running kind k8s dev cluster"
    vpc_id      = data.aws_vpc.default.id

    ingress_cidr_blocks = ["0.0.0.0/0"]
    ingress_rules       = ["http-80-tcp", "https-443-tcp", "all-icmp", "ssh-tcp", "kubernetes-api-tcp"]
    egress_rules        = ["all-all"]
}

resource "aws_eip" "eip" {
  vpc   = true
  instance = module.ec2.id[0]
}


resource "aws_kms_key" "this" {  
}

resource "aws_network_interface" "this" {
 count  = 1
 subnet_id  = tolist(data.aws_subnet_ids.all.ids)[count.index] 
}

module "ec2" {
    source = "terraform-aws-modules/ec2-instance/aws"
    version = "~> 2.0"

    instance_count      = 1
    name                = "kind-k8s-cluster-instance"
    ami                 = "ami-09d9c897fc36713bf" #ubuntu server 20.04 LTS
    instance_type       = var.instance_size
    subnet_id           = tolist(data.aws_subnet_ids.all.ids)[0]
    vpc_security_group_ids      = [module.security_group.security_group_id]
    associate_public_ip_address = true
    key_name            = var.key_name

    user_data_base64 = base64encode(local.user_data)

    enable_volume_tags = false
    root_block_device = [
        {
        volume_type = "gp2"
        volume_size = var.drive_size
        tags = {
            Name = "my-root-block"
        }
        },
    ]

    ebs_block_device = [
        {
        device_name = "/dev/sdf"
        volume_type = "gp2"
        volume_size = 5
        encrypted   = true
        kms_key_id  = aws_kms_key.this.arn
        }
    ]

    tags = {
        "Env"      = "Private"
        "Location" = "Secret"
    }
    
}
provider "aws" {
    region = "us-west-2"
}

locals {
    user_data = <<EOF
#!/bin/bash
apt update
apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null


curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | \
 tee /etc/apt/sources.list.d/kubernetes.list

apt-get update

apt-get install -y docker-ce docker-ce-cli containerd.io kubectl

curl -Lo /tmp/kind https://kind.sigs.k8s.io/dl/v0.11.0/kind-linux-arm64
chmod +x /tmp/kind
mv /tmp/kind /usr/bin/kind



EOF
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
    instance_type       = "t4g.large"
    subnet_id           = tolist(data.aws_subnet_ids.all.ids)[0]
    vpc_security_group_ids      = [module.security_group.security_group_id]
    associate_public_ip_address = true
    key_name            = "default_aws_key"

    user_data_base64 = base64encode(local.user_data)

    enable_volume_tags = false
    root_block_device = [
        {
        volume_type = "gp2"
        volume_size = 100
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
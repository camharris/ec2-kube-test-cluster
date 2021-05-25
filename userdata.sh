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

echo """
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: aws-kind
networking:
  apiServerAddress: "0.0.0.0"
  apiServerPort: 6443
nodes:
- role: control-plane
  image: rossgeorgiev/kind-node-arm64:v1.20.0
""" > /root/kind.yml

/usr/bin/kind create cluster --config /root/kind.yml
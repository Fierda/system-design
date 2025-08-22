#!/bin/bash
set -xe

# Install updates
yum update -y

# Install Docker (if needed)
amazon-linux-extras enable docker
yum install -y docker
systemctl enable docker
systemctl start docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# Join the EKS cluster (replace with your cluster name & region)
# The eksctl or bootstrap.sh from AWS can also be used
/etc/eks/bootstrap.sh my-eks-cluster --region ap-southeast-1

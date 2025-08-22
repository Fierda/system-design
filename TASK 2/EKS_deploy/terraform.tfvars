region     = "ap-southeast-1"
project_name = "eks-node-go"

# Use Amazon EKS Optimized AMI (depends on your region & k8s version)
ami_id     = "ami-0a12345b6c78de90f"

instance_type = "t3.medium"

# Your own subnet + vpc
subnet_id  = "subnet-0123456789abcdef0"
vpc_id     = "vpc-0123456789abcdef0"

# Control plane CIDR (normally your VPC CIDR)
cluster_security_group_cidr = "10.0.0.0/16"

# Your AWS key pair for SSH
key_name   = "my-keypair"

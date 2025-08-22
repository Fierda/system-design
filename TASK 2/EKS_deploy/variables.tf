variable "region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "eks-demo"
}

variable "ami_id" {
  description = "AMI ID for EKS worker nodes (use Amazon EKS Optimized AMI)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "subnet_id" {
  description = "Subnet ID where EC2 will be launched"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for EKS worker nodes"
  type        = string
}

variable "cluster_security_group_cidr" {
  description = "CIDR block for EKS control plane communication"
  type        = string
  default     = "0.0.0.0/0"
}

variable "key_name" {
  description = "EC2 Key pair for SSH"
  type        = string
}

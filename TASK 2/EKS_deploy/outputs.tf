output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.eks_node.id
}

output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.eks_node.public_ip
}

output "ec2_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.eks_node.private_ip
}

output "security_group_id" {
  description = "Security group ID for worker nodes"
  value       = aws_security_group.eks_nodes.id
}

output "iam_instance_profile" {
  description = "IAM Instance Profile for EC2 worker nodes"
  value       = aws_iam_instance_profile.eks_node_instance_profile.name
}

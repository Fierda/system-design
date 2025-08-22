variable "app_name" {
  type        = string
  default     = "node-go-app"
}

variable "environment" {
  type        = string
  default     = "dev"
}

variable "ami_id" {
  type        = string
  description = "AMI ID for EC2"
}

variable "instance_type" {
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  type        = string
  description = "EC2 Key Pair"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID"
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of Security Group IDs"
}

variable "associate_public_ip_address" {
  type        = bool
  default     = true
  description = "Whether to associate a public IP address"
}

variable "user_data_script" {
  type        = string
  default     = "bootstrap.sh"
  description = "Path to user data script"
}

variable "tags" {
  type        = map(string)
  default     = {}
}

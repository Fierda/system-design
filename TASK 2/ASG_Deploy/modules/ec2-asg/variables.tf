variable "app_name" {
  description = "Application name"
  type        = string
}

variable "environment" {
  description = "Environment (Production, Staging, etc.)"
  type        = string
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "EC2 key pair (null if using SSM only)"
  type        = string
  default     = null
}

variable "bootstrap_script_path" {
  description = "Path to bootstrap script"
  type        = string
  default     = null
}

variable "security_group_ids" {
  description = "Security group IDs"
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

variable "instance_profile" {
  description = "IAM instance profile"
  type        = string
  default     = null
}

variable "associate_public_ip" {
  description = "Assign public IP to instances"
  type        = bool
  default     = false
}

variable "asg_config" {
  description = "Auto Scaling Group configuration"
  type = object({
    min_size         = number
    max_size         = number
    desired_capacity = number
  })
}

variable "health_check_type" {
  description = "Health check type (EC2 or ELB)"
  type        = string
  default     = "EC2"
}

variable "health_check_grace_period" {
  description = "Grace period for health checks"
  type        = number
  default     = 300
}

variable "termination_policies" {
  description = "ASG termination policies"
  type        = list(string)
  default     = ["OldestInstance"]
}

variable "scaling_policy_config" {
  description = "Scaling policies for ASG"
  type = object({
    scale_out = object({
      adjustment = number
      type       = string
    })
    scale_in = object({
      adjustment = number
      type       = string
    })
  })
  default = {
    scale_out = {
      adjustment = 1
      type       = "ChangeInCapacity"
    }
    scale_in = {
      adjustment = -1
      type       = "ChangeInCapacity"
    }
  }
}

variable "cpu_alarm_config" {
  description = "CPU alarm configuration"
  type = object({
    threshold           = number
    scale_in_threshold  = number
    evaluation_periods  = number
    period              = number
    comparison_operator = string
    statistic           = string
  })
  default = {
    threshold           = 80
    scale_in_threshold  = 20
    evaluation_periods  = 2
    period              = 60
    comparison_operator = "GreaterThanThreshold"
    statistic           = "Average"
  }
}

variable "memory_alarm_config" {
  description = "Memory alarm configuration"
  type = object({
    threshold           = number
    evaluation_periods  = number
    period              = number
    comparison_operator = string
    statistic           = string
    namespace           = string
  })
  default = {
    threshold           = 90
    evaluation_periods  = 2
    period              = 60
    comparison_operator = "GreaterThanThreshold"
    statistic           = "Average"
    namespace           = "CustomMetrics"
  }
}

variable "enable_memory_alarm" {
  description = "Enable memory alarm (requires CW Agent)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}

variable "bootstrap_script_path" {
  description = "Path to bootstrap script (installs app & CW agent)"
  type        = string
  default     = "bootstrap.sh"
}

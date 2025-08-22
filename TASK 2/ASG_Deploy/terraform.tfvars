# General
app_name    = "node-go"
environment = "Staging"

# EC2 details
ami_id        = "ami-0fedcba9876543210"
instance_type = "t3.small"
key_name      = "my-ssh-key"

# Networking
subnet_ids         = ["subnet-xyz111", "subnet-xyz222"]
security_group_ids = ["sg-09876abcdef12345"]

# IAM
instance_profile = "EC2-SSM-Role"

# ASG Config
asg_config = {
  min_size         = 1
  max_size         = 3
  desired_capacity = 1
}

# CPU alarms
cpu_alarm_config = {
  threshold           = 85
  scale_in_threshold  = 30
  evaluation_periods  = 2
  period              = 60
  comparison_operator = "GreaterThanThreshold"
  statistic           = "Average"
}

# Memory alarms
enable_memory_alarm = true
memory_alarm_config = {
  threshold           = 90
  evaluation_periods  = 2
  period              = 60
  comparison_operator = "GreaterThanThreshold"
  statistic           = "Average"
  namespace           = "CWAgent"
}

# Tags
tags = {
  Owner       = "DevOpsTeam"
  Environment = "Staging"
}

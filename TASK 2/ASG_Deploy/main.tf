provider "aws" {
  region = "ap-southeast-1"
}

# Node.js Frontend Auto Scaling Group
module "node_fe_asg" {
  source = "./modules/ec2-asg"
  
  app_name    = "node-fe"
  environment = "Production"
  ami_id        = "ami-0abcd1234efgh5678"  # Consider using different AMI for frontend
  instance_type = "t3.medium"
  subnet_ids         = ["subnet-aaa111", "subnet-bbb222"]
  security_group_ids = ["sg-0123456789abcdef"]  # Consider separate SG for frontend
  instance_profile = "EC2-SSM-Role"
  
  asg_config = {
    min_size         = 2
    max_size         = 5
    desired_capacity = 3
  }
  
  cpu_alarm_config = {
    threshold           = 70
    scale_in_threshold  = 25
    evaluation_periods  = 2
    period              = 60
    comparison_operator = "GreaterThanThreshold"
    statistic           = "Average"
  }
  
  enable_memory_alarm = true
  memory_alarm_config = {
    threshold           = 75
    evaluation_periods  = 2
    period              = 60
    comparison_operator = "GreaterThanThreshold"
    statistic           = "Average"
    namespace           = "CWAgent"
  }
  
  tags = {
    Project     = "MyApp FE"
    ManagedBy   = "Me"
    CostCenter  = "R&D"
    Component   = "Frontend"
    Technology  = "NodeJS"
  }
}

# Go Backend Auto Scaling Group
module "go_be_asg" {
  source = "./modules/ec2-asg"
  
  app_name    = "go-be"
  environment = "Production"
  ami_id        = "ami-0abcd1234efgh5678"  # Consider using different AMI for backend
  instance_type = "t3.medium"
  subnet_ids         = ["subnet-aaa111", "subnet-bbb222"]  # Consider private subnets for backend
  security_group_ids = ["sg-0123456789abcdef"]  # Consider separate SG for backend
  instance_profile = "EC2-SSM-Role"
  
  asg_config = {
    min_size         = 2
    max_size         = 5
    desired_capacity = 3
  }
  
  cpu_alarm_config = {
    threshold           = 85
    scale_in_threshold  = 25
    evaluation_periods  = 2
    period              = 60
    comparison_operator = "GreaterThanThreshold"
    statistic           = "Average"
  }
  
  enable_memory_alarm = true
  memory_alarm_config = {
    threshold           = 90
    evaluation_periods  = 2
    period              = 60
    comparison_operator = "GreaterThanThreshold"
    statistic           = "Average"
    namespace           = "CWAgent"
  }
  
  tags = {
    Project     = "MyApp BE"
    ManagedBy   = "Me"
    CostCenter  = "R&D"
    Component   = "Backend"
    Technology  = "Go"
  }
}
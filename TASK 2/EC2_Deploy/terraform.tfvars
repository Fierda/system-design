ami_id        = "ami-0abcdef1234567890"
instance_type = "t3.medium"
key_name      = "my-key"
subnet_id     = "subnet-0123456789abcdef"
security_group_ids = ["sg-0123456789abcdef"]

tags = {
  Owner   = "Popo21"
  Purpose = "Dev Environment"
}

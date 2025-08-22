provider "aws" {
  region = "ap-southeast-1"
}

module "ec2" {
  source = "./modules/ec2"

  ami_id             = "ami-xxxxxxxx"   # Ubuntu 22.04
  instance_type      = "t3.medium"
  key_name           = "my-key"
  subnet_id          = "subnet-123456"
  security_group_ids = ["sg-123456"]

  tags = {
    Project = "MyApp"
  }
}

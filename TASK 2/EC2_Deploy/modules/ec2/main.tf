resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  associate_public_ip_address = var.associate_public_ip_address
  vpc_security_group_ids     = var.security_group_ids
  
  # Better path handling for user_data
  user_data = var.user_data_script != "" ? file("${path.module}/${var.user_data_script}") : null

  tags = merge(
    {
      Name = "${var.app_name}-${var.environment}"
    },
    var.tags
  )
}

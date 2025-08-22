locals {
  common_tags = merge({
    Name        = var.app_name
    Environment = var.environment
  }, var.tags)
}

resource "aws_launch_template" "this" {
  name_prefix   = "${var.app_name}-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  dynamic "key_name" {
    for_each = var.key_name != null ? [var.key_name] : []
    content {
      key_name = key_name.value
    }
  }

  user_data = var.bootstrap_script_path != null ? base64encode(file(var.bootstrap_script_path)) : null

  iam_instance_profile {
    name = var.instance_profile
  }

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip
    security_groups             = var.security_group_ids
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.common_tags
  }

  tags = local.common_tags
}

resource "aws_autoscaling_group" "this" {
  name                      = "${var.app_name}-asg"
  max_size                  = var.asg_config.max_size
  min_size                  = var.asg_config.min_size
  desired_capacity          = var.asg_config.desired_capacity
  vpc_zone_identifier       = var.subnet_ids
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  termination_policies      = var.termination_policies

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${var.app_name}-scale-out"
  scaling_adjustment     = var.scaling_policy_config.scale_out.adjustment
  adjustment_type        = var.scaling_policy_config.scale_out.type
  autoscaling_group_name = aws_autoscaling_group.this.name
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${var.app_name}-scale-in"
  scaling_adjustment     = var.scaling_policy_config.scale_in.adjustment
  adjustment_type        = var.scaling_policy_config.scale_in.type
  autoscaling_group_name = aws_autoscaling_group.this.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.app_name}-HighCPU"
  comparison_operator = var.cpu_alarm_config.comparison_operator
  evaluation_periods  = var.cpu_alarm_config.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.cpu_alarm_config.period
  statistic           = var.cpu_alarm_config.statistic
  threshold           = var.cpu_alarm_config.threshold
  alarm_actions       = [aws_autoscaling_policy.scale_out.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.app_name}-LowCPU"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.cpu_alarm_config.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.cpu_alarm_config.period
  statistic           = var.cpu_alarm_config.statistic
  threshold           = var.cpu_alarm_config.scale_in_threshold
  alarm_actions       = [aws_autoscaling_policy.scale_in.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "ram_high" {
  count               = var.enable_memory_alarm ? 1 : 0
  alarm_name          = "${var.app_name}-HighRAM"
  comparison_operator = var.memory_alarm_config.comparison_operator
  evaluation_periods  = var.memory_alarm_config.evaluation_periods
  metric_name         = "MemoryUtilization"
  namespace           = var.memory_alarm_config.namespace
  period              = var.memory_alarm_config.period
  statistic           = var.memory_alarm_config.statistic
  threshold           = var.memory_alarm_config.threshold
  alarm_actions       = [aws_autoscaling_policy.scale_out.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }

  tags = local.common_tags
}

resource "aws_iam_role" "ec2_role" {
  name               = "EC2-SSM-Role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2-SSM-Profile"
  role = aws_iam_role.ec2_role.name
}


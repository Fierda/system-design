output "launch_template_id" {
  value       = aws_launch_template.this.id
  description = "Launch template ID"
}

output "autoscaling_group_name" {
  value       = aws_autoscaling_group.this.name
  description = "ASG name"
}

output "scale_out_policy_arn" {
  value       = aws_autoscaling_policy.scale_out.arn
  description = "Scale-out policy ARN"
}

output "scale_in_policy_arn" {
  value       = aws_autoscaling_policy.scale_in.arn
  description = "Scale-in policy ARN"
}

output "cpu_high_alarm_arn" {
  value       = aws_cloudwatch_metric_alarm.cpu_high.arn
  description = "CPU high alarm ARN"
}

output "cpu_low_alarm_arn" {
  value       = aws_cloudwatch_metric_alarm.cpu_low.arn
  description = "CPU low alarm ARN"
}

output "ram_high_alarm_arn" {
  value       = try(aws_cloudwatch_metric_alarm.ram_high[0].arn, null)
  description = "RAM high alarm ARN (if enabled)"
}

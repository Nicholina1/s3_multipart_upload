output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.s3_access_logs.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.s3_access_logs.arn
}

output "metric_filter_name" {
  description = "Name of the unauthorized access metric filter"
  value       = aws_cloudwatch_log_metric_filter.unauthorized_access.name
}

output "alarm_name" {
  description = "Name of the unauthorized access alarm"
  value       = aws_cloudwatch_metric_alarm.unauthorized_access_alarm.alarm_name
}

output "alarm_arn" {
  description = "ARN of the unauthorized access alarm"
  value       = aws_cloudwatch_metric_alarm.unauthorized_access_alarm.arn
}
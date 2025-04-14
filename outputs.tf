output "bucket_name" {
  value = module.s3.bucket_name
}

output "kms_key_arn" {
  value = module.kms.key_arn
}

output "admin_credentials" {
  value = {
    access_key = aws_iam_access_key.admin_user.id
    secret_key = aws_iam_access_key.admin_user.secret
  }
  sensitive = true
}

output "editor_credentials" {
  value = {
    access_key = aws_iam_access_key.editor_user.id
    secret_key = aws_iam_access_key.editor_user.secret
  }
  sensitive = true
}
output "admin_user_arn" {
  value = aws_iam_user.admin_user.arn
}

output "editor_user_arn" {
  value = aws_iam_user.editor_user.arn
}

output "security_alarms" {
  description = "Security monitoring resources"
  value       = module.monitoring.*
  sensitive   = true
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for security alerts"
  value       = aws_sns_topic.security_alerts.arn
}





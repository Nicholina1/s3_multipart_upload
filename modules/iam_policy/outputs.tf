output "policy_arn" {
  description = "ARN of the created IAM policy"
  value       = aws_iam_policy.s3_upload_policy.arn
}

output "policy_name" {
  description = "Name of the created IAM policy"
  value       = aws_iam_policy.s3_upload_policy.name
}
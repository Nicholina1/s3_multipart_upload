
output "key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.s3_upload_key.arn
}

output "key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.s3_upload_key.key_id
}

output "alias_arn" {
  description = "ARN of the KMS key alias"
  value       = aws_kms_alias.s3_upload_key_alias.arn
}
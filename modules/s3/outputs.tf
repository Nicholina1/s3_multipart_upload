output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.upload_bucket.arn
}

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.upload_bucket.bucket
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the bucket"
  value       = aws_s3_bucket.upload_bucket.bucket_regional_domain_name
}

output "accelerated_endpoint" {
  value = aws_s3_bucket.upload_bucket.bucket_regional_domain_name
  description = "Use this with 's3-accelerate' endpoint for faster transfers"
}
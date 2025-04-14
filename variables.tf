variable "aws_region" {
  description = "AWS region to deploy infrastructure"
  type        = string
  default     = "us-east-1"
}

# variable "bucket_prefix" {
#   default = "secure-bucket"
# }

# variable "account_id" {
#   default = ""
# }
variable "enable_monitoring" {
  description = "Whether to enable CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "unauthorized_access_threshold" {
  description = "Number of unauthorized attempts to trigger alarm"
  type        = number
  default     = 3
}

# variable "sns_topic_arn" {
#   description = "ARN of SNS topic for security alerts"
#   type        = string
# }

variable "log_retention_days" {
  description = "CloudWatch log retention period"
  type        = number
  default     = 90
}

# locals {
#   bucket_name   = "secure-bucket-${random_id.suffix.hex}"
#   policy_suffix = random_id.suffix.hex
# }
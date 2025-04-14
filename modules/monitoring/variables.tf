variable "bucket_name" {
  description = "Name of the S3 bucket to monitor"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for sending alerts"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 90
}

variable "unauthorized_access_threshold" {
  description = "Number of unauthorized attempts to trigger alarm"
  type        = number
  default     = 5
}

variable "alarm_evaluation_period" {
  description = "Evaluation period for alarms in seconds"
  type        = number
  default     = 300
}

variable "alarm_namespace" {
  description = "CloudWatch namespace for security metrics"
  type        = string
  default     = "S3Security"
}
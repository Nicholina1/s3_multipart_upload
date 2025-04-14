resource "aws_cloudwatch_log_group" "s3_access_logs" {
  name              = "/aws/s3/${var.bucket_name}/access-logs"
  retention_in_days = var.log_retention_days
  # kms_key_id        = var.kms_key_arn # Optional: Add if you want to encrypt logs with KMS
}

resource "aws_cloudwatch_log_metric_filter" "unauthorized_access" {
  name           = "${var.bucket_name}-UnauthorizedAccessAttempts"
  pattern = "{ ($.errorCode = \"AccessDenied\" || $.errorCode = \"UnauthorizedOperation\") }"
  log_group_name = aws_cloudwatch_log_group.s3_access_logs.name

  metric_transformation {
    name      = "UnauthorizedAccessAttempts"
    namespace = var.alarm_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "unauthorized_access_alarm" {
  alarm_name          = "s3-${var.bucket_name}-unauthorized-access"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnauthorizedAccessAttempts"
  namespace           = var.alarm_namespace
  period              = var.alarm_evaluation_period
  statistic           = "Sum"
  threshold           = var.unauthorized_access_threshold
  alarm_description   = "This alarm triggers when multiple unauthorized access attempts are detected for bucket ${var.bucket_name}"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_arn]

  tags = {
    Environment = "Production"
    Monitoring  = "Security"
  }
}

# Optional: Add additional alarms for other suspicious activities
resource "aws_cloudwatch_log_metric_filter" "suspicious_operations" {
  name           = "${var.bucket_name}-SuspiciousOperations"
  pattern = "{ ($.eventName = \"DeleteBucket\" || $.eventName = \"PutBucketPolicy\" || $.eventName = \"PutBucketAcl\") }"
  log_group_name = aws_cloudwatch_log_group.s3_access_logs.name

  metric_transformation {
    name      = "SuspiciousOperations"
    namespace = var.alarm_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "suspicious_operations_alarm" {
  alarm_name          = "s3-${var.bucket_name}-suspicious-operations"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "SuspiciousOperations"
  namespace           = var.alarm_namespace
  period              = var.alarm_evaluation_period
  statistic           = "Sum"
  threshold           = "1" # Alert on any occurrence
  alarm_description   = "This alarm triggers when sensitive bucket operations are detected for ${var.bucket_name}"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_arn]

  tags = {
    Environment = "Production"
    Monitoring  = "Security"
  }
}
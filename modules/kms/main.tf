data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "kms_key_policy" {
  # Root account access
  statement {
    sid    = "EnableRootPermissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Conditional role access
  dynamic "statement" {
    for_each = var.upload_role_arn != "" ? [1] : []
    content {
      sid    = "EnableRolePermissions"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = [var.upload_role_arn]
      }
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]
      resources = ["*"]
    }
  }

  # Optional: Add additional service principals if needed
  dynamic "statement" {
    for_each = var.allow_cloudtrail ? [1] : []
    content {
      sid    = "AllowCloudTrailEncrypt"
      effect = "Allow"
      principals {
        type        = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
      }
      actions   = ["kms:GenerateDataKey*"]
      resources = ["*"]
    }
  }
}

resource "aws_kms_key" "s3_upload_key" {
  description             = "KMS key for S3 upload encryption"
  deletion_window_in_days = var.deletion_window
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_key_policy.json
}

resource "aws_kms_alias" "s3_upload_key_alias" {
  name          = "alias/${var.key_alias}"
  target_key_id = aws_kms_key.s3_upload_key.key_id
}
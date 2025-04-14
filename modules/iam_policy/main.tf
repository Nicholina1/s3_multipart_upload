resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  policy_statements = {
    admin = [
      {
        sid     = "FullBucketAccess"
        effect  = "Allow"
        actions = ["s3:*", "kms:*"]
        resources = [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*",
          var.kms_key_arn
        ]
      }
    ],
    editor = [
      {
        sid    = "AllowS3Upload"
        effect = "Allow"
        actions = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        resources = [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
      },
      {
        sid    = "AllowKMSUsage"
        effect = "Allow"
        actions = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        resources = [var.kms_key_arn]
      }
    ]
    # viewer = [
    #   {
    #     sid    = "AllowS3View"
    #     effect = "Allow"
    #     actions = [
    #       "s3:GetObject",
    #       "s3:ListBucket"
    #     ]
    #     resources = [
    #       "arn:aws:s3:::${var.bucket_name}",
    #       "arn:aws:s3:::${var.bucket_name}/*"
    #     ]
    #   },
    #   {
    #     sid    = "AllowKMSDecrypt"
    #     effect = "Allow"
    #     actions = [
    #       "kms:Decrypt",
    #       "kms:DescribeKey"
    #     ]
    #     resources = [var.kms_key_arn]
    #   }
    # ]
  }
}

data "aws_iam_policy_document" "combined" {
  dynamic "statement" {
    for_each = local.policy_statements[var.permission_level]
    content {
      sid       = statement.value.sid
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

resource "aws_iam_policy" "s3_upload_policy" {
  name        = "${var.bucket_name}-${var.permission_level}-policy-${random_id.suffix.hex}"
  description = "S3 access policy for ${var.permission_level} role"
  policy      = data.aws_iam_policy_document.combined.json
  lifecycle {
    create_before_destroy = true
  }
}
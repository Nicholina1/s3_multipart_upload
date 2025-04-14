provider "random" {}

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  bucket_name   = "secure-bucket-${random_id.suffix.hex}"
  policy_suffix = random_id.suffix.hex
}

# 1. Create KMS module
module "kms" {
  source          = "./modules/kms"
  key_alias       = "secure-uploads-key"
  upload_role_arn = module.iam_role.role_arn
  deletion_window = 30
}

# 2. Create S3 bucket
module "s3" {
  source             = "./modules/s3"
  bucket_name        = local.bucket_name
  kms_key_arn        = module.kms.key_arn
  versioning_enabled = true
  expiration_days    = 2
  allowed_user_agent = "secure_uploader"
}

# 3. Create the base IAM policy
module "iam_policy" {
  source      = "./modules/iam_policy"
  policy_name = "${local.bucket_name}-base-policy"
  bucket_name = module.s3.bucket_name
  kms_key_arn = module.kms.key_arn
}

# 4. Create IAM role
module "iam_role" {
  source           = "./modules/iam_role"
  role_name        = "${local.bucket_name}-upload-role"
  policy_arn       = module.iam_policy.policy_arn
  trusted_services = ["lambda.amazonaws.com"]
}

# 5. Update KMS policy to include the role ARN
resource "aws_kms_key_policy" "update_policy" {
  key_id = module.kms.key_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "EnableRolePermissions"
        Effect = "Allow"
        Principal = {
          AWS = module.iam_role.role_arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# 6. Create SNS topic for alerts
resource "aws_sns_topic" "security_alerts" {
  name = "${local.bucket_name}-security-alerts"
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.security_alerts.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    resources = [aws_sns_topic.security_alerts.arn]
  }
}

# 7. Setup monitoring
module "monitoring" {
  source        = "./modules/monitoring"
  bucket_name   = module.s3.bucket_name
  sns_topic_arn = aws_sns_topic.security_alerts.arn
  # kms_key_arn   = module.kms.key_arn

  log_retention_days            = var.log_retention_days
  unauthorized_access_threshold = var.unauthorized_access_threshold
}

# 8. Create role-specific policies
module "admin_policy" {
  source           = "./modules/iam_policy"
  policy_name      = "${local.bucket_name}-admin-policy-${local.policy_suffix}"
  bucket_name      = module.s3.bucket_name
  kms_key_arn      = module.kms.key_arn
  permission_level = "admin"
}

module "editor_policy" {
  source           = "./modules/iam_policy"
  policy_name      = "${local.bucket_name}-editor-policy"
  bucket_name      = module.s3.bucket_name
  kms_key_arn      = module.kms.key_arn
  permission_level = "editor"
}

# Create users
resource "aws_iam_user" "admin_user" {
  name = "${local.bucket_name}-admin"
}

resource "aws_iam_user" "editor_user" {
  name = "${local.bucket_name}-editor"
}

# Create access keys
resource "aws_iam_access_key" "admin_user" {
  user = aws_iam_user.admin_user.name
}

resource "aws_iam_access_key" "editor_user" {
  user = aws_iam_user.editor_user.name
}

# Attach policies
resource "aws_iam_user_policy_attachment" "admin_policy" {
  user       = aws_iam_user.admin_user.name
  policy_arn = module.admin_policy.policy_arn
}

resource "aws_iam_user_policy_attachment" "editor_policy" {
  user       = aws_iam_user.editor_user.name
  policy_arn = module.editor_policy.policy_arn
}

data "aws_caller_identity" "current" {}

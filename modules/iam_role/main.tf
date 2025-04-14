resource "aws_iam_role" "s3_upload_role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}
data "aws_iam_policy_document" "assume_role_policy" {
  # For AWS services (like EC2, Lambda)
  dynamic "statement" {
    for_each = var.trusted_services != null ? [1] : []
    content {
      actions = ["sts:AssumeRole"]
      principals {
        type        = "Service"
        identifiers = var.trusted_services
      }
    }
  }

  # For IAM users/roles
  # dynamic "statement" {
  #   for_each = var.trusted_principals != null ? [1] : []
  #   content {
  #     actions = ["sts:AssumeRole"]
  #     principals {
  #       type        = "AWS"
  #       identifiers = var.trusted_principals
  #     }
  #   }
  # }
}
# data "aws_iam_policy_document" "assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRole"]
#
#     principals {
#       type        = "Service"
#       identifiers = var.trusted_services
#     }
#   }
# }

resource "aws_iam_role_policy_attachment" "s3_upload_policy_attachment" {
  role       = aws_iam_role.s3_upload_role.name
  policy_arn = var.policy_arn
}
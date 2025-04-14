# Create a separate logging bucket
resource "aws_s3_bucket" "access_logs_bucket" {
  bucket = "${var.bucket_name}-access-logs"
}

# For logging bucket, we need to enable ACLs explicitly
resource "aws_s3_bucket_ownership_controls" "access_logs" {
  bucket = aws_s3_bucket.access_logs_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "access_logs_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.access_logs]
  
  bucket = aws_s3_bucket.access_logs_bucket.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Main upload bucket (ACLs disabled by default)
resource "aws_s3_bucket" "upload_bucket" {
  bucket = var.bucket_name
}

# Enable logging on the main bucket
resource "aws_s3_bucket_logging" "upload_bucket" {
  bucket        = aws_s3_bucket.upload_bucket.id
  target_bucket = aws_s3_bucket.access_logs_bucket.id
  target_prefix = "logs/"
}

# Transfer acceleration configuration
resource "aws_s3_bucket_accelerate_configuration" "upload_bucket" {
  bucket = aws_s3_bucket.upload_bucket.id
  status = "Enabled"
}

# Security configurations
resource "aws_s3_bucket_public_access_block" "upload_bucket" {
  bucket = aws_s3_bucket.upload_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "upload_bucket" {
  bucket = aws_s3_bucket.upload_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "upload_bucket" {
  bucket = aws_s3_bucket.upload_bucket.id
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "upload_bucket" {
  bucket = aws_s3_bucket.upload_bucket.id

  rule {
    id     = "abort-incomplete-multipart-upload"
    status = "Enabled"
    filter {
      prefix = ""
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  dynamic "rule" {
    for_each = var.expiration_days != null ? [1] : []
    content {
      id     = "object-expiration"
      status = "Enabled"
      filter {
        prefix = ""
      }
      expiration {
        days = var.expiration_days
      }
    }
  }
}
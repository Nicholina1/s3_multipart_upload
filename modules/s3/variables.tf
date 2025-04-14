variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encryption"
  type        = string
}

variable "versioning_enabled" {
  description = "Enable versioning for the bucket"
  type        = bool
  default     = false
}
variable "allowed_user_agent" {
  description = "User agent string to restrict presigned URL access"
  type        = string
  default     = "secure_uploader"
}
variable "expiration_days" {
  description = "Number of days after which objects expire (null for no expiration)"
  type        = number
  default     = null
}
variable "key_alias" {
  description = "Alias name for the KMS key (without the 'alias/' prefix)"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9:/_-]+$", var.key_alias))
    error_message = "Key alias must only contain alphanumeric characters, forward slashes, underscores, and hyphens."
  }
}

variable "upload_role_arn" {
  description = "ARN of the IAM role that will use this key (leave empty if not needed)"
  type        = string
  default     = ""
}

variable "deletion_window" {
  description = "Number of days to retain the KMS key after deletion (7-30)"
  type        = number
  default     = 30
  validation {
    condition     = var.deletion_window >= 7 && var.deletion_window <= 30
    error_message = "Deletion window must be between 7 and 30 days."
  }
}

variable "allow_cloudtrail" {
  description = "Whether to allow CloudTrail to use this key for encryption"
  type        = bool
  default     = false
}
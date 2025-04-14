variable "role_name" {
  description = "Name of the IAM role"
  type        = string
}

variable "policy_arn" {
  description = "ARN of the policy to attach to the role"
  type        = string
}

variable "trusted_services" {
  description = "List of AWS service principals that can assume this role (e.g., ec2.amazonaws.com, lambda.amazonaws.com)"
  type        = list(string)
  default     = []
}

variable "trusted_principals" {
  description = "List of IAM principals (users or roles) that can assume this role (ARN format: arn:aws:iam::ACCOUNT_ID:user/USERNAME)"
  type        = list(string)
  default     = []
}

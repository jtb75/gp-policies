variable "region" {
  description = "AWS region for test resources"
  type        = string
  default     = "us-east-1"
}

variable "untrusted_account_id" {
  description = "An AWS account ID NOT in the trusted lists, used to simulate untrusted sharing"
  type        = string
  default     = "999999999999"
}

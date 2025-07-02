variable "account_id" {
  description = "AWS Account ID where the S3 bucket will be created"
  type        = string
}

variable "region" {
  description = "AWS region where the S3 bucket will be created"
  type        = string
}

variable "environment" {
  description = "Environment (e.g., development, staging, production)"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "versioning_enabled" {
  description = "Whether to enable versioning for the S3 bucket"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to the S3 bucket"
  type        = map(string)
  default     = {}
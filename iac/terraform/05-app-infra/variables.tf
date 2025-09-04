variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "application_name" {
  description = "Name of the application"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket for initialization data"
  type        = string
}

variable "kms_deletion_window" {
  description = "Duration in days before KMS key deletion"
  type        = number
}

variable "kms_key_alias" {
  description = "Alias for the KMS key"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

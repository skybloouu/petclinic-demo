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

# Kubernetes namespace where application runs
variable "application_namespace" {
  description = "Kubernetes namespace of the application service account"
  type        = string
  default     = "petclinic"
}

# Service account name used by the application (Helm chart controlled)
variable "service_account_name" {
  description = "Service account name for IRSA trust (must match Helm chart)"
  type        = string
  default     = "spring-petclinic"
}

# ECR repository name
variable "ecr_repository_name" {
  description = "Name of the ECR repository to create"
  type        = string
  default     = "spring-petclinic"
}

# GitHub repository owner (organization or user)
variable "github_owner" {
  description = "GitHub organization or user that owns the repository used in Actions"
  type        = string
}

# GitHub repository name
variable "github_repo" {
  description = "GitHub repository name used for pushing images"
  type        = string
}

# GitHub branch allowed to assume the OIDC role
variable "github_branch" {
  description = "GitHub branch name allowed to push (e.g. main)"
  type        = string
  default     = "main"
}

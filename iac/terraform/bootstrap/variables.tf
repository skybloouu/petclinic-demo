#############################################
# Central variable declarations (no defaults)
# All values must be supplied via terraform.tfvars or -var/-var-file.
#############################################

variable "github_owner" {
  description = "GitHub organization / user that owns the repository"
  type        = string
}

variable "github_repo" {
  description = "Repository name (without owner)"
  type        = string
}

variable "allowed_branches" {
  description = "List of branch names allowed to assume the role"
  type        = list(string)
}

variable "create_github_oidc_provider" {
  description = "Set false if GitHub OIDC provider already exists in the account"
  type        = bool
}

variable "existing_github_oidc_provider_arn" {
  description = "If not creating, supply existing provider ARN"
  type        = string
}

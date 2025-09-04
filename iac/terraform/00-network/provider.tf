provider "aws" {
  region = var.region
  # Use environment credentials for GitHub Actions compatibility
  # (credentials will be provided by the OIDC role)
  # profile = "personal"
}

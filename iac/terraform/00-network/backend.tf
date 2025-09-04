terraform {
  backend "s3" {
    bucket = "stackgen-terraform-state"
    key    = "env/00-network/terraform.tfstate"
    region = "ap-south-1"
    # Remove profile for GitHub Actions compatibility
    # profile = "personal"

    # Enable state locking using DynamoDB
    # dynamodb_table parameter is deprecated in newer versions
    # dynamodb_table = "terraform-state-lock"
    # Use this instead if needed:
    use_lockfile = true
    encrypt      = true
  }
}

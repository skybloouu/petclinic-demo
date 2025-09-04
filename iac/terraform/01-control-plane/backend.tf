terraform {
  backend "s3" {
    bucket  = "stackgen-terraform-state"
    key     = "env/01-control-plane/terraform.tfstate"
    region  = "ap-south-1"
    profile = "personal"

    # Enable state locking using DynamoDB
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

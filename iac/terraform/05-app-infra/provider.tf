terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.9"
    }
  }
}

provider "aws" {
  profile = "personal"
  region  = "ap-south-1"
}

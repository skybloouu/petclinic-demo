terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# S3 bucket for pet types initialization
resource "aws_s3_bucket" "init_bucket" {
  bucket = var.bucket_name

  tags = merge(
    {
      Environment = var.environment
    },
    var.tags
  )
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "init_bucket_versioning" {
  bucket = aws_s3_bucket.init_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption for S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "init_bucket_encryption" {
  bucket = aws_s3_bucket.init_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.pet_types_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# KMS key for pet types encryption
resource "aws_kms_key" "pet_types_key" {
  description             = "KMS key for encrypting ${var.application_name} initialization data"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true

  tags = merge(
    {
      Environment = var.environment
      Purpose     = "Data Encryption"
    },
    var.tags
  )
}

# KMS key alias
resource "aws_kms_alias" "pet_types_key_alias" {
  name          = "alias/${var.kms_key_alias}"
  target_key_id = aws_kms_key.pet_types_key.key_id
}

# IAM role for the application
resource "aws_iam_role" "app_role" {
  name = "${var.application_name}-app-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    {
      Environment = var.environment
    },
    var.tags
  )
}

# IAM policy for S3 access
resource "aws_iam_role_policy" "s3_access" {
  name = "${var.application_name}-s3-access-${var.environment}"
  role = aws_iam_role.app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.init_bucket.arn}/*"
        ]
      }
    ]
  })
}

# IAM policy for KMS access
resource "aws_iam_role_policy" "kms_access" {
  name = "${var.application_name}-kms-access-${var.environment}"
  role = aws_iam_role.app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = [
          aws_kms_key.pet_types_key.arn
        ]
      }
    ]
  })
}

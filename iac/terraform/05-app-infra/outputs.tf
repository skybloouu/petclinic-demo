output "s3_bucket_name" {
  description = "Name of the S3 bucket created for initialization data"
  value       = aws_s3_bucket.init_bucket.id
}

output "kms_key_arn" {
  description = "ARN of the KMS key created for data encryption"
  value       = aws_kms_key.pet_types_key.arn
}

output "app_role_arn" {
  description = "ARN of the IAM role created for the application"
  value       = aws_iam_role.app_role.arn
}

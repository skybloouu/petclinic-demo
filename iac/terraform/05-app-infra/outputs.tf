output "s3_bucket_name" {
  description = "Name of the S3 bucket created for initialization data"
  value       = aws_s3_bucket.init_bucket.id
}

output "kms_key_arn" {
  description = "ARN of the KMS key created for data encryption"
  value       = aws_kms_key.pet_types_key.arn
}

output "app_irsa_role_arn" {
  description = "ARN of the IAM role assumed via IRSA by the application"
  value       = aws_iam_role.app_irsa.arn
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "github_ecr_push_role_arn" {
  description = "IAM Role ARN for GitHub Actions to push images"
  value       = aws_iam_role.github_ecr_push.arn
}

# Aurora MySQL Outputs
output "aurora_mysql_endpoint" {
  description = "The endpoint of the Aurora MySQL cluster"
  value       = aws_rds_cluster.aurora_mysql.endpoint
}

output "aurora_mysql_reader_endpoint" {
  description = "The reader endpoint of the Aurora MySQL cluster"
  value       = aws_rds_cluster.aurora_mysql.reader_endpoint
}

output "aurora_mysql_port" {
  description = "The port of the Aurora MySQL cluster"
  value       = aws_rds_cluster.aurora_mysql.port
}

output "aurora_mysql_database_name" {
  description = "The database name of the Aurora MySQL cluster"
  value       = aws_rds_cluster.aurora_mysql.database_name
}

output "aurora_mysql_secret_arn" {
  description = "The ARN of the Secrets Manager secret storing DB credentials"
  value       = aws_secretsmanager_secret.petclinic_db_secret.arn
}

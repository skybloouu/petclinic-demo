# Application Infrastructure (05-app-infra)

This module provisions the AWS infrastructure components needed by the Spring PetClinic application. It focuses on the application-specific infrastructure rather than the shared components (like the EKS control plane).

## Overview

The 05-app-infra module provides:

1. **Aurora MySQL Serverless v2 Database**: A scalable, cost-efficient database to store application data
2. **Amazon ECR Repository**: For storing Docker container images of the application
3. **S3 Bucket**: For storing application initialization data
4. **IAM Roles with IRSA**: For secure Kubernetes pod access to AWS resources
5. **GitHub OIDC Integration**: For secure CI/CD pipeline access to AWS resources
6. **KMS Keys**: For data encryption

## Module Dependencies

This module has dependencies on:
- **00-network**: Provides VPC, subnets, and networking infrastructure
- **01-control-plane**: Provides EKS cluster details, particularly OIDC provider information

## Components

### 1. Aurora MySQL Serverless v2

The module provisions an Aurora MySQL Serverless v2 cluster with the following configurations:

- **Serverless v2 Scaling**: Auto-scales between 0.5 and 1.0 ACUs (Aurora Capacity Units)
- **MySQL 8.0 Compatible**: Uses engine version "8.0.mysql_aurora.3.04.1"
- **Secure Authentication**: Auto-generates random database credentials
- **Secrets Manager Integration**: Stores database credentials securely
- **Security Group**: Restricts database access to the EKS cluster network
- **Performance Insights**: Enabled with 7-day retention (free tier)
- **Database Parameters**: UTF8MB4 character set and collation
- **CloudWatch Logs**: Exports audit, error, general, and slow query logs
- **Deletion Protection**: Enabled for production environments
- **Private Subnets**: Database is placed in dedicated data subnets

### 2. Amazon ECR Repository

A Docker container registry for the application with:

- **Image Scanning**: Automatically scans images for vulnerabilities on push
- **Lifecycle Policy**: Keeps only the last 10 images to manage storage costs
- **Encryption**: Server-side encryption with AES-256

### 3. S3 Bucket for Application Data

A storage bucket used for application initialization data:

- **Versioning**: Enabled to track changes to uploaded files
- **Encryption**: Server-side encryption using KMS
- **Access Controls**: Limited to the application through IAM roles

### 4. IAM Roles with IRSA (IAM Roles for Service Accounts)

This module creates IAM roles that integrate with Kubernetes service accounts through IRSA:

- **Application Role**: Used by the application pods to securely access AWS resources:
  - S3 access for pet types initialization data
  - KMS access for encryption/decryption
  - Secrets Manager access for database credentials

- **GitHub Actions Role**: Used by CI/CD pipelines to push container images:
  - ECR push/pull permissions
  - Limited to specific GitHub repository and branch

### 5. KMS Encryption

- **KMS Key**: Dedicated key for encrypting application data
- **Key Rotation**: Enabled for enhanced security
- **Key Alias**: For easier key identification and usage

## Security Features

This module implements several security best practices:

1. **Principle of Least Privilege**: IAM roles have minimal permissions required
2. **Network Isolation**: Database is in private subnets with restricted security groups
3. **Encryption in Transit and at Rest**: For all data components
4. **Secret Rotation**: Database passwords can be rotated through Secrets Manager
5. **OIDC Federation**: Secure token-based authentication for CI/CD and Kubernetes
6. **No Long-lived Credentials**: Uses short-lived tokens for all authentication

## Configuration Variables

Key configuration variables for this module include:

| Variable | Description | Default |
|----------|-------------|---------|
| `environment` | Deployment environment (dev/staging/prod) | - |
| `application_name` | Name of the application | - |
| `bucket_name` | Name of the S3 initialization bucket | - |
| `application_namespace` | Kubernetes namespace for application | `petclinic` |
| `service_account_name` | Kubernetes service account name | `spring-petclinic` |
| `github_owner` | GitHub organization/user name | - |
| `github_repo` | GitHub repository name | - |
| `github_branch` | GitHub branch for CI/CD integration | `main` |

## Outputs

This module exports several outputs that can be used by other modules or in deployment configurations:

| Output | Description |
|--------|-------------|
| `aurora_mysql_endpoint` | Database writer endpoint |
| `aurora_mysql_reader_endpoint` | Database reader endpoint |
| `aurora_mysql_port` | Database port |
| `aurora_mysql_secret_arn` | ARN of the database credentials secret |
| `app_irsa_role_arn` | ARN of the application IAM role |
| `ecr_repository_url` | URL of the ECR repository |
| `github_ecr_push_role_arn` | ARN of the GitHub Actions IAM role |
| `s3_bucket_name` | Name of the S3 initialization bucket |
| `kms_key_arn` | ARN of the KMS encryption key |

## Infrastructure as Code Approach

This module follows infrastructure as code best practices:

1. **Remote State References**: Uses Terraform remote state to reference other modules
2. **Resource Tagging**: All resources are tagged for organizational clarity
3. **Lifecycle Management**: Handles sensitive values like passwords appropriately
4. **Environment Separation**: Supports different environments through variables
5. **Preconditions**: Validates dependencies are in place before provisioning

## Integration with Kubernetes

This module integrates with Kubernetes through:

1. **IRSA**: IAM roles for service accounts to provide AWS permissions to pods
2. **Secrets Manager**: For secure access to database credentials
3. **ECR**: For container image repository access

## Cost Optimization

Several cost optimization features are built into this module:

1. **Aurora Serverless v2**: Scales down to 0.5 ACUs during low usage periods
2. **ECR Lifecycle Policies**: Automatically cleans up old images
3. **Single Instance Configuration**: Uses only one database instance for non-production environments

## Deployment Workflow

Typical deployment order:
1. Deploy 00-network module
2. Deploy 01-control-plane module
3. Deploy 05-app-infra module
4. Deploy application Helm chart (referencing outputs from this module)

# Infrastructure Bootstrap Module

This module implements the foundational components required for Terraform state management and CI/CD integration. It establishes the infrastructure prerequisites needed before any other infrastructure can be deployed via Terraform.

## Overview

The bootstrap module provides:

1. **Remote State Management**: S3 bucket for storing Terraform state files
2. **State Locking**: DynamoDB table for Terraform state locking
3. **CI/CD Integration**: GitHub Actions OIDC integration for secure, key-less AWS access
4. **Security Controls**: Access controls and encryption for state storage

## Purpose

This module should be applied **once** at the beginning of your infrastructure journey. It creates the infrastructure that will be referenced by all subsequent Terraform modules for state management. It also establishes the secure authentication method for CI/CD pipelines to access AWS.

## Components

### 1. Terraform State Storage (S3)

A dedicated S3 bucket for storing Terraform state files with the following features:

- **Versioning**: Tracks all changes to state files
- **Encryption**: Server-side encryption with AES-256
- **Lifecycle Protection**: Prevents accidental deletion of the bucket
- **Public Access Block**: Comprehensive protection against any public access

### 2. State Locking (DynamoDB)

A DynamoDB table that provides state locking to prevent concurrent Terraform operations:

- **On-demand Capacity**: Cost-efficient pay-per-request billing
- **Simple Schema**: Single partition key "LockID" for Terraform state locks

### 3. GitHub Actions Integration (OIDC)

Secure authentication for GitHub Actions workflows using OpenID Connect:

- **OIDC Provider**: Integration with GitHub Actions as an identity provider
- **IAM Role**: Role specific to GitHub Actions with trusted relationship
- **Repository Scoping**: Limited to specific GitHub repositories and branches
- **Session Limits**: Controlled session duration for enhanced security

### 4. Least-Privilege Permissions

Fine-grained IAM policies that follow security best practices:

- **State Bucket Access**: Minimal permissions to read/write state files
- **Lock Table Access**: Permissions for acquiring/releasing state locks
- **Identity Verification**: Basic identity check permissions

## Security Features

This module implements several security best practices:

1. **No Long-lived Credentials**: Uses OIDC federation instead of long-lived access keys
2. **Repository Scope Restrictions**: Limits access to specified repositories and branches
3. **Encryption in Transit and at Rest**: For all state storage
4. **Public Access Prevention**: Multiple layers of protection against public exposure
5. **Least Privilege Access**: Minimal permissions granted to CI/CD pipelines

## Configuration Variables

Key configuration variables for this module include:

| Variable | Description | Default |
|----------|-------------|---------|
| `github_owner` | GitHub organization/user name | - |
| `github_repo` | GitHub repository name | - |
| `allowed_branches` | List of branches allowed to assume role | - |
| `create_github_oidc_provider` | Whether to create a new OIDC provider | - |
| `existing_github_oidc_provider_arn` | ARN of existing OIDC provider if not creating | - |

## Outputs

This module exports outputs that will be used by other modules and CI/CD workflows:

| Output | Description |
|--------|-------------|
| `github_actions_role_arn` | ARN of the IAM role for GitHub Actions to assume |
| `github_oidc_provider_arn` | ARN of the GitHub OIDC identity provider |

## Usage in CI/CD Pipelines

The module includes commented example code for GitHub Actions workflow implementation. Key points:

1. **Required Permissions**: `id-token: write` for OIDC token issuance
2. **No AWS Secrets**: No need to store AWS access keys as GitHub secrets
3. **Role Assumption**: Uses the `aws-actions/configure-aws-credentials` action with the role ARN
4. **State Protection**: Workflows only apply changes from approved branches

## Extended Permissions (Optional)

The module includes commented examples for extending permissions when needed:

1. **State-only Access**: Default implementation only grants access to state resources
2. **Infrastructure Deployment**: Commented examples show how to add permissions for resource provisioning
3. **Service-specific Policies**: Guidelines for adding fine-grained permissions

## Bootstrapping Process

When first setting up this infrastructure:

1. **Local Application**: Initially apply this module locally with administrative AWS credentials
2. **Commit Configuration**: Commit the Terraform code (without sensitive values)
3. **CI/CD Setup**: Configure GitHub Actions with the role ARN output
4. **Self-management**: Future changes to this module can be applied via CI/CD

## Important Notes

- **Apply Once**: This module should generally only be applied once per AWS account/region
- **Role ARN Security**: The role ARN output is sensitive and should be stored securely
- **Branch Protection**: Consider implementing branch protection rules in GitHub
- **State Backups**: Consider additional backup strategies for the state bucket
- **Access Reviews**: Periodically review who has access to repositories with deployment rights

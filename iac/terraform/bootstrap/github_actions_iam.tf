#############################################
# GitHub Actions OIDC Role for Terraform
# ---------------------------------------
# This file creates:
# 1. (Optional) GitHub OIDC provider
# 2. IAM role assumable via OIDC from specific repo/branches
# 3. Least‑privilege policy for Terraform state (S3 + DynamoDB lock)
#
# Adjust branches / environments as needed. For broader resource
# deployment permissions, attach additional policies (see notes below).
#############################################

#############################################
# Variables moved to variables.tf (all values supplied via terraform.tfvars)
#############################################

#############################################
# (Optional) GitHub OIDC Provider
# If this already exists in the account, set create_github_oidc_provider=false
#############################################
resource "aws_iam_openid_connect_provider" "github" {
  count          = var.create_github_oidc_provider ? 1 : 0
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # Current GitHub Actions root CA thumbprint (subject to change if GitHub rotates certs)
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

locals {
  github_oidc_provider_arn = var.create_github_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_github_oidc_provider_arn

  # Build the list of allowed sub claims for branches: repo:owner/repo:ref:refs/heads/<branch>
  github_branch_subs = [for b in var.allowed_branches : "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/${b}"]
}

#############################################
# Assume Role Policy Document
#############################################
data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.github_branch_subs
    }
  }
}

#############################################
# IAM Role for Terraform via GitHub Actions
#############################################
resource "aws_iam_role" "github_actions_terraform" {
  name                 = "github-actions-terraform"
  assume_role_policy   = data.aws_iam_policy_document.github_actions_assume_role.json
  max_session_duration = 3600
  tags = {
    ManagedBy = "terraform"
    Purpose   = "GitHubActionsOIDC"
  }
}

#############################################
# Least Privilege Policy for Terraform State Backend Access
# (Grants only S3 + DynamoDB + STS identity lookup.)
#############################################
data "aws_iam_policy_document" "terraform_state_access" {
  statement {
    sid = "AllowStateBucketCRUD"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketVersioning",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      aws_s3_bucket.terraform_state.arn,
      "${aws_s3_bucket.terraform_state.arn}/*"
    ]
  }

  statement {
    sid = "AllowDynamoDBLockTableAccess"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:UpdateItem",
      "dynamodb:DescribeTable"
    ]
    resources = [aws_dynamodb_table.terraform_locks.arn]
  }

  statement {
    sid       = "ReadIdentity"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "terraform_state_access" {
  name        = "terraform-state-access"
  description = "Least privilege access to S3 state bucket and DynamoDB lock table for Terraform runs"
  policy      = data.aws_iam_policy_document.terraform_state_access.json
}

resource "aws_iam_role_policy_attachment" "attach_state_access" {
  role       = aws_iam_role.github_actions_terraform.name
  policy_arn = aws_iam_policy.terraform_state_access.arn
}

#############################################
# (Optional) Attach broader permissions for applying infrastructure.
# Uncomment and change as needed. For production, craft fine-grained
# policies per service instead of using PowerUser / Administrator.
#############################################
# resource "aws_iam_role_policy_attachment" "optional_power_user" {
#   role       = aws_iam_role.github_actions_terraform.name
#   policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
# }

#############################################
# Outputs
#############################################
output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions_terraform.arn
  description = "IAM Role ARN to configure in GitHub Actions workflow (role-to-assume)"
}

output "github_oidc_provider_arn" {
  value       = local.github_oidc_provider_arn
  description = "ARN of the GitHub OIDC provider used for the IAM role"
}

#############################################
# Usage Notes:
# 1. Provide the variables (github_owner, github_repo, allowed_branches) either via
#    terraform.tfvars, CLI -var, or a variables file.
# 2. In the GitHub repository settings, no secrets needed for AWS keys; rely on OIDC.
# 3. GitHub Actions workflow example:
#
# name: Terraform
# on:
#   push:
#     branches: [ main ]
# permissions:
#   id-token: write   # Required for OIDC
#   contents: read
# jobs:
#   plan-apply:
#     runs-on: ubuntu-latest
#     steps:
#       - uses: actions/checkout@v4
#       - name: Configure AWS credentials
#         uses: aws-actions/configure-aws-credentials@v4
#         with:
#           role-to-assume: ${{ secrets.TERRAFORM_ROLE_ARN }} # or hardcode the ARN
#           aws-region: ap-south-1
#       - name: Setup Terraform
#         uses: hashicorp/setup-terraform@v3
#         with:
#           terraform_version: 1.9.3
#       - name: Terraform Init
#         run: terraform -chdir=petclinic-demo/iac/terraform/bootstrap init
#       - name: Terraform Plan
#         run: terraform -chdir=petclinic-demo/iac/terraform/bootstrap plan -input=false
#       - name: Terraform Apply
#         if: github.ref == 'refs/heads/main'
#         run: terraform -chdir=petclinic-demo/iac/terraform/bootstrap apply -auto-approve -input=false
#
# 4. Store the role ARN as an Actions secret (e.g., TERRAFORM_ROLE_ARN) or reference output directly if hard coded.
# 5. Extend permissions by adding/attaching additional IAM policies referencing resources provisioned by later stages.
#############################################

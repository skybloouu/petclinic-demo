#############################
# ECR Repository & GitHub OIDC Push Role
#############################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# OpenID Connect provider for GitHub Actions (only created once per account/region ideally)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
  tags = merge({
    Name        = "github-oidc-provider"
    Environment = var.environment
  }, var.tags)
}

# ECR repository
resource "aws_ecr_repository" "app" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  encryption_configuration { encryption_type = "AES256" }

  tags = merge({
    Environment = var.environment
    Application = var.application_name
  }, var.tags)
}

# (Optional) Lifecycle policy - keep only last N images (default 10)
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}

# Trust policy for GitHub OIDC (restrict to specific repo + branch)
data "aws_iam_policy_document" "gha_oidc_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/${var.github_branch}"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# Inline policy granting minimal ECR push/pull permissions on this repository
data "aws_iam_policy_document" "github_ecr_permissions" {
  statement {
    sid    = "ECRAuth"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ECRPushPull"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = [
      aws_ecr_repository.app.arn
    ]
  }
}

resource "aws_iam_role" "github_ecr_push" {
  name               = "${var.application_name}-github-ecr-push-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.gha_oidc_assume_role.json
  tags = merge({
    Environment = var.environment
    Application = var.application_name
    Purpose     = "GitHubActionsECRPush"
  }, var.tags)
}

resource "aws_iam_role_policy" "github_ecr_push_inline" {
  name   = "${var.application_name}-github-ecr-push-policy-${var.environment}"
  role   = aws_iam_role.github_ecr_push.id
  policy = data.aws_iam_policy_document.github_ecr_permissions.json
}

#############################
# Helpful Outputs (also appended in outputs.tf)
#############################

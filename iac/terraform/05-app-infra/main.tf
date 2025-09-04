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


#############################
# IRSA Role for Kubernetes Application (replaces legacy EC2 assume role)
#############################

# Remote state to fetch EKS OIDC provider info from control-plane stack
data "terraform_remote_state" "control_plane" {
  backend = "s3"
  config = {
    bucket  = "stackgen-terraform-state"
    key     = "env/01-control-plane/terraform.tfstate"
    region  = "ap-south-1"
    profile = "personal"
  }
}

locals {
  oidc_provider_arn    = try(data.terraform_remote_state.control_plane.outputs.oidc_provider_arn, "")
  oidc_issuer_url      = try(data.terraform_remote_state.control_plane.outputs.cluster_oidc_issuer_url, "")
  oidc_hostpath        = local.oidc_issuer_url == "" ? "" : replace(local.oidc_issuer_url, "https://", "")
  service_account_ns   = var.application_namespace
  service_account_name = var.service_account_name
  sa_sub_claim         = "system:serviceaccount:${local.service_account_ns}:${local.service_account_name}"
}

data "aws_iam_policy_document" "app_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_hostpath}:sub"
      values   = [local.sa_sub_claim]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_hostpath}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "app_permissions" {
  statement {
    sid       = "S3ReadPetTypes"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.init_bucket.arn}/*"]
  }
  statement {
    sid       = "KMSDecryptPetTypes"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.pet_types_key.arn]
  }
}
resource "aws_iam_role" "app_irsa" {
  name               = "${var.application_name}-irsa-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.app_trust.json
  tags = merge({
    Environment = var.environment
    Application = var.application_name
  }, var.tags)

  lifecycle {
    precondition {
      condition     = local.oidc_provider_arn != ""
      error_message = "OIDC provider ARN is empty. Apply the 01-control-plane stack with outputs.tf exposing oidc_provider_arn before creating IRSA role."
    }
    precondition {
      condition     = local.oidc_hostpath != ""
      error_message = "OIDC issuer URL is empty. Ensure control-plane state includes cluster_oidc_issuer_url output."
    }
  }
}

resource "aws_iam_role_policy" "app_irsa_inline" {
  name   = "${var.application_name}-irsa-inline-${var.environment}"
  role   = aws_iam_role.app_irsa.id
  policy = data.aws_iam_policy_document.app_permissions.json
}

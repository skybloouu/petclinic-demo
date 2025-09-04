#############################
# EKS Add-on IAM (IRSA) Roles (Control Plane Layer)
# Provides IAM roles for:
#  - AWS Load Balancer Controller
#  - cert-manager (DNS01 via Route53)
#############################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

########################################
# Locals derive OIDC provider info from cluster module output
########################################

locals {
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.cluster_oidc_issuer_url
  oidc_hostpath     = replace(local.oidc_provider_url, "https://", "")

  alb_sa_subject          = "system:serviceaccount:kube-system:aws-load-balancer-controller"
  cert_manager_sa_subject = "system:serviceaccount:cert-manager:cert-manager"
}

########################################
# Optional input variables (hosted zone / domain). Add to variables.tf if you plan to set via tfvars.
########################################

variable "hosted_zone_id" {
  description = "(Optional) Route53 hosted zone ID for ExternalDNS & cert-manager DNS01"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "(Optional) Base domain name managed in the hosted zone (e.g. example.com)"
  type        = string
  default     = ""
}

########################################
# Trust Policies
########################################

data "aws_iam_policy_document" "alb_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_hostpath}:sub"
      values   = [local.alb_sa_subject]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_hostpath}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}


data "aws_iam_policy_document" "cert_manager_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_hostpath}:sub"
      values   = [local.cert_manager_sa_subject]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_hostpath}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

########################################
# Policies
########################################

data "aws_iam_policy_document" "alb_controller" {
  statement {
    effect = "Allow"
    actions = [
      # ACM (cert discovery for HTTPS listeners)
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "acm:GetCertificate",
      "ec2:Describe*",
      "ec2:GetCoipPoolUsage",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:GetSecurityGroupsForVpc",
      # Added required security group lifecycle permissions for ALB controller
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:Create*",
      "elasticloadbalancing:Delete*",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:Modify*",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:RemoveTags",
      "iam:CreateServiceLinkedRole",
      "cognito-idp:DescribeUserPoolClient",
      # Route53 read-only (some ALB features reference hosted zone info)
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "waf-regional:GetWebACLForResource",
      "waf-regional:AssociateWebACL",
      "waf-regional:DisassociateWebACL",
      "wafv2:GetWebACL",
      "wafv2:GetWebACLForResource",
      "wafv2:AssociateWebACL",
      "wafv2:DisassociateWebACL",
      "shield:DescribeProtection",
      "shield:GetSubscriptionState",
      "shield:DeleteProtection",
      "shield:CreateProtection",
      "shield:DescribeSubscription",
      "shield:ListProtections"
    ]
    resources = ["*"]
  }
}


data "aws_iam_policy_document" "cert_manager" {
  # Always allow safe read/list operations (needed even without DNS01 challenges)
  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:GetChange"
    ]
    resources = ["*"]
  }

  # Only include the change-set permissions if a hosted zone ID was supplied.
  # Avoids emitting an empty resources array which caused the MalformedPolicyDocument error.
  dynamic "statement" {
    for_each = var.hosted_zone_id == "" ? [] : [var.hosted_zone_id]
    content {
      effect    = "Allow"
      actions   = ["route53:ChangeResourceRecordSets"]
      resources = ["arn:aws:route53:::hostedzone/${statement.value}"]
    }
  }
}

########################################
# IAM Roles & Inline Policies
########################################

resource "aws_iam_role" "alb_controller" {
  name               = "${var.cluster_name}-alb-controller"
  assume_role_policy = data.aws_iam_policy_document.alb_trust.json
  tags = {
    Environment = var.environment
    Purpose     = "ALBController"
  }
}
resource "aws_iam_role_policy" "alb_controller_inline" {
  name   = "${var.cluster_name}-alb-controller-policy"
  role   = aws_iam_role.alb_controller.id
  policy = data.aws_iam_policy_document.alb_controller.json
}


resource "aws_iam_role" "cert_manager" {
  name               = "${var.cluster_name}-cert-manager"
  assume_role_policy = data.aws_iam_policy_document.cert_manager_trust.json
  tags = {
    Environment = var.environment
    Purpose     = "CertManagerDNS01"
  }
}
resource "aws_iam_role_policy" "cert_manager_inline" {
  name   = "${var.cluster_name}-cert-manager-policy"
  role   = aws_iam_role.cert_manager.id
  policy = data.aws_iam_policy_document.cert_manager.json
}

########################################
# Outputs
########################################

output "alb_controller_role_arn" { value = aws_iam_role.alb_controller.arn }
output "cert_manager_role_arn" { value = aws_iam_role.cert_manager.arn }

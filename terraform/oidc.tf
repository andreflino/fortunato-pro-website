# terraform/oidc.tf
# OIDC configuration for secure GitHub Actions authentication

# GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = merge(local.tags, {
    Name = "GitHub Actions OIDC Provider"
  })
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "${local.site_name}-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${local.repository}:ref:refs/heads/${local.config.github.auto_deploy_branch}"
        }
      }
    }]
  })

  tags = merge(local.tags, {
    Name = "GitHub Actions Role"
  })
}

# IAM Policy for GitHub Actions (comprehensive permissions)
resource "aws_iam_policy" "github_actions" {
  name        = "${local.site_name}-github-actions-policy"
  description = "Policy for GitHub Actions deployment with Terraform state access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # S3 Website Bucket Access
      {
        Sid    = "S3WebsiteBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = [
          aws_s3_bucket.website.arn,
          "${aws_s3_bucket.website.arn}/*"
        ]
      },
      # CloudFront Access
      {
        Sid    = "CloudFrontAccess"
        Effect = "Allow"
        Action = [
          "cloudfront:*"
        ]
        Resource = "*"
      },
      # CloudWatch Access
      {
        Sid    = "CloudWatchAccess"
        Effect = "Allow"
        Action = [
          "cloudwatch:*",
          "logs:*"
        ]
        Resource = "*"
      },
      # IAM Access (for managing roles and policies)
      {
        Sid    = "IAMAccess"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:GetOpenIDConnectProvider",
          "iam:ListOpenIDConnectProviders",
          "iam:CreateRole",
          "iam:CreatePolicy",
          "iam:CreateOpenIDConnectProvider",
          "iam:TagRole",
          "iam:TagPolicy",
          "iam:TagOpenIDConnectProvider",
          "iam:PutRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:PassRole",
          "iam:UpdateRole",
          "iam:UpdateOpenIDConnectProviderThumbprint"
        ]
        Resource = [
          "arn:aws:iam::*:role/${local.site_name}-*",
          "arn:aws:iam::*:oidc-provider/token.actions.githubusercontent.com",
          "arn:aws:iam::*:policy/${local.site_name}-*"
        ]
      },
      # General AWS Access
      {
        Sid    = "GeneralAWSAccess"
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity",
          "sts:TagSession"
        ]
        Resource = "*"
      },
      # Budgets and Cost Management
      {
        Sid    = "BudgetsAccess"
        Effect = "Allow"
        Action = [
          "budgets:*",
          "ce:*"
        ]
        Resource = "*"
      },
      # Route53 (for DNS)
      {
        Sid    = "Route53Access"
        Effect = "Allow"
        Action = [
          "route53:*"
        ]
        Resource = "*"
      },
      # ACM (for SSL certificates)
      {
        Sid    = "ACMAccess"
        Effect = "Allow"
        Action = [
          "acm:*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.tags, {
    Name = "GitHub Actions Policy"
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}
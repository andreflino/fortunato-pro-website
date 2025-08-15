# terraform/state-access.tf
# Policy for accessing manually created Terraform state bucket

# IAM policy for Terraform state access
data "aws_iam_policy_document" "terraform_state_access" {
  # S3 state bucket access
  statement {
    sid    = "TerraformStateS3Access"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning"
    ]
    resources = [
      "arn:aws:s3:::${local.config.terraform.state_bucket_name}",
      "arn:aws:s3:::${local.config.terraform.state_bucket_name}/*"
    ]
  }

  # DynamoDB lock table access
  statement {
    sid    = "TerraformStateDynamoDBAccess"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable"
    ]
    resources = [
      "arn:aws:dynamodb:*:*:table/${local.config.terraform.lock_table_name}"
    ]
  }
}

# Create the policy
resource "aws_iam_policy" "terraform_state_access" {
  name        = "${local.site_name}-terraform-state-access"
  description = "Policy for accessing manually created Terraform state bucket and lock table"
  policy      = data.aws_iam_policy_document.terraform_state_access.json

  tags = merge(local.tags, {
    Name        = "Terraform State Access Policy"
    Purpose     = "Terraform State Management"
    Environment = local.config.environment
  })
}

# Attach state access policy to GitHub Actions role
resource "aws_iam_role_policy_attachment" "github_actions_state_access" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.terraform_state_access.arn
}
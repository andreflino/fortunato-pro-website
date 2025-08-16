# terraform/main.tf
# Clean Terraform configuration for static website - FREE TIER OPTIMIZED
terraform {
  required_version = ">= 1.0"
  
  backend "s3" {
    bucket         = "fortunato-pro-terraform-state"  # Create this first
    key            = "fortunato-pro/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    #dynamodb_table = "terraform-locks"  # For state locking
  }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Load configuration from YAML
locals {
  config = yamldecode(file("../config/site.yaml"))
  
  # Extract values for easy reference
  site_name    = local.config.name
  domain       = local.config.domain
  environment  = local.config.environment
  repository   = local.config.repository
  
  # AWS region (us-east-1 for free tier optimization)
  aws_region = "us-east-1"  # Best region for free tier
  
  # Free tier optimized CloudFront settings
  cloudfront_price_class = "PriceClass_100"  # Only US, Canada, Europe (cheapest)
  
  # Cache settings optimized for free tier
  cache_seconds = {
    "5m"  = 300
    "30m" = 1800
    "1h"  = 3600
    "6h"  = 21600
    "24h" = 86400
  }[local.config.cdn.cache_duration]
  
  # Standard tags
  tags = {
    Name        = local.site_name
    Environment = local.environment
    Repository  = local.repository
    ManagedBy   = "Terraform"
    Domain      = local.domain
    CostOptimization = "FreeTier"
  }
}

# Default provider
provider "aws" {
  region = local.aws_region
  default_tags {
    tags = local.tags
  }
}

# Provider for us-east-1 (required for CloudFront certificates)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  
  default_tags {
    tags = local.tags
  }
}

# Random suffix for unique S3 bucket name
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# SSL Certificate for CloudFront (must be in us-east-1)
resource "aws_acm_certificate" "website" {
  provider = aws.us_east_1  # CloudFront requires certificates in us-east-1
  
  domain_name               = local.domain
  subject_alternative_names = ["www.${local.domain}"]
  validation_method         = "DNS"
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = merge(local.tags, {
    Name = "SSL Certificate for ${local.domain}"
  })
}

# Certificate validation (you'll need to add these DNS records to Cloudflare manually)
resource "aws_acm_certificate_validation" "website" {
  provider = aws.us_east_1
  
  certificate_arn = aws_acm_certificate.website.arn
  
  # Note: Since you're using Cloudflare for DNS, you'll need to manually add
  # the validation records to Cloudflare. Terraform will output these for you.
  
  timeouts {
    create = "10m"
  }
}

# S3 Bucket for website hosting
resource "aws_s3_bucket" "website" {
  bucket = "${local.site_name}-${random_string.bucket_suffix.result}"
}

# S3 Bucket versioning (free tier: 5GB)
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id
  versioning_configuration {
    status = local.config.storage.versioning ? "Enabled" : "Suspended"
  }
}

# S3 Bucket encryption (always enabled, no extra cost)
resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket lifecycle (keep within free tier limits)
resource "aws_s3_bucket_lifecycle_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    id     = "delete_old_versions"
    status = "Enabled"

    # Add this filter block
    filter {
      prefix = ""  # Apply to all objects
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# S3 Bucket public access (SECURE - block all public access)
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id
  
  block_public_acls       = true   # Block public ACLs
  block_public_policy     = true   # Block public bucket policies
  ignore_public_acls      = true   # Ignore existing public ACLs
  restrict_public_buckets = true   # Restrict public bucket policies
}

# S3 Bucket policy for CloudFront Origin Access Control ONLY
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  depends_on = [aws_s3_bucket_public_access_block.website]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontServicePrincipal"
      Effect    = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action   = "s3:GetObject"
      Resource = "${aws_s3_bucket.website.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.website[0].id}"
        }
      }
    }]
  })
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# CloudFront Origin Access Control (secure S3 access)
resource "aws_cloudfront_origin_access_control" "website" {
  count = local.config.cdn.enabled ? 1 : 0
  
  name                              = "${local.site_name}-oac"
  description                       = "Origin Access Control for ${local.site_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Security headers policy (no extra cost)
resource "aws_cloudfront_response_headers_policy" "security_headers" {
  count = local.config.security.security_headers && local.config.cdn.enabled ? 1 : 0
  name  = "${local.site_name}-security-headers"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      override                   = true
    }
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
  }
}

# CloudFront Distribution with SSL Certificate and Custom Domains
resource "aws_cloudfront_distribution" "website" {
  count = local.config.cdn.enabled ? 1 : 0

  # Add custom domain aliases
  aliases = [
    local.domain,
    "www.${local.domain}"
  ]

  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.website[0].id
    origin_id                = "S3-${local.site_name}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for ${local.domain}"
  default_root_object = "index.html"  # This fixes the 403 error!

  # FREE TIER: PriceClass_100 (US, Canada, Europe only - cheapest)
  price_class = local.cloudfront_price_class

  # Cache behavior optimized for free tier
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${local.site_name}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    # Security headers policy
    response_headers_policy_id = local.config.security.security_headers ? aws_cloudfront_response_headers_policy.security_headers[0].id : null

    # Longer cache times = fewer origin requests = stays in free tier
    min_ttl     = 0
    default_ttl = local.cache_seconds
    max_ttl     = 86400
  }

  # Custom error pages for SPA behavior
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL Certificate configuration
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.website.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # Wait for certificate validation
  depends_on = [aws_acm_certificate_validation.website]

  wait_for_deployment = true
}

# Cost monitoring alarm (free tier focused)
resource "aws_cloudwatch_metric_alarm" "cost_alert" {
  alarm_name          = "${local.site_name}-cost-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400"
  statistic           = "Maximum"
  threshold           = local.config.cost.monthly_budget
  alarm_description   = "Cost alert for ${local.site_name} - should stay under $${local.config.cost.monthly_budget}"
  treat_missing_data  = "notBreaching"

  dimensions = {
    Currency = "USD"
  }
}
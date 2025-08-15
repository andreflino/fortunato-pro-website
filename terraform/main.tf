# terraform/main.tf
# Clean Terraform configuration for static website - FREE TIER OPTIMIZED
terraform {
  required_version = ">= 1.0"
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

provider "aws" {
  region = local.aws_region
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

# S3 Bucket public access (required for website hosting)
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id
  
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 Bucket policy for public read access
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  depends_on = [aws_s3_bucket_public_access_block.website]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.website.arn}/*"
    }]
  })
}

# S3 Bucket website configuration
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "index.html"
  }
}

# CloudFront Origin Access Control (free tier: 1TB transfer/month)
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
      override                   = true  # Add this line
    }
    content_type_options {
      override = true  # This was missing
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

# CloudFront Distribution (FREE TIER OPTIMIZED)
resource "aws_cloudfront_distribution" "website" {
  count = local.config.cdn.enabled ? 1 : 0
  
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.website[0].id
    origin_id                = "S3-${aws_s3_bucket.website.id}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "${local.site_name} - FREE TIER OPTIMIZED"
  
  # FREE TIER: PriceClass_100 (US, Canada, Europe only - cheapest)
  price_class = local.cloudfront_price_class

  # Cache behavior optimized for free tier
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]  # Reduced methods to minimize costs
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.website.id}"
    compress               = true
    viewer_protocol_policy = local.config.security.https_only ? "redirect-to-https" : "allow-all"

    # Add security headers if enabled
    response_headers_policy_id = local.config.security.security_headers ? aws_cloudfront_response_headers_policy.security_headers[0].id : null

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    # Longer cache times = fewer origin requests = stays in free tier
    min_ttl     = 86400    # 1 day minimum
    default_ttl = local.cache_seconds
    max_ttl     = 31536000 # 1 year maximum
  }

  # Custom error responses for SPA
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
    error_caching_min_ttl = 300
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1"
  }

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

# Remote state handle
terraform {
  backend "s3" {
    bucket         = "fortunato-pro-terraform-state"  # Create this first
    key            = "fortunato-pro/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    #dynamodb_table = "terraform-locks"  # For state locking
  }
}
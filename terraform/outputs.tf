# terraform/outputs.tf
# Useful outputs for deployment and monitoring

output "website_url" {
  description = "Website URL via CloudFront"
  value       = local.config.cdn.enabled ? "https://${aws_cloudfront_distribution.website[0].domain_name}" : "http://${aws_s3_bucket.website.bucket}.s3-website-${local.aws_region}.amazonaws.com"
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.website.id
}

output "s3_website_url" {
  description = "S3 direct website URL"
  value       = "http://${aws_s3_bucket.website.bucket}.s3-website-${local.aws_region}.amazonaws.com"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = local.config.cdn.enabled ? aws_cloudfront_distribution.website[0].id : null
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name (for DNS pointing)"
  value       = local.config.cdn.enabled ? aws_cloudfront_distribution.website[0].domain_name : null
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  value       = aws_iam_role.github_actions.arn
}

output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = local.aws_region
}

output "environment" {
  description = "Deployment environment"
  value       = local.environment
}

output "domain_instructions" {
  description = "Instructions for setting up your third-party domain"
  value = <<-EOT
    
    DOMAIN SETUP INSTRUCTIONS:
    
    1. Copy this CloudFront URL: ${local.config.cdn.enabled ? aws_cloudfront_distribution.website[0].domain_name : "Direct S3 hosting"}
    
    2. Go to your domain provider (${local.config.domain_config.dns_provider}) DNS settings
    
    3. Add these DNS records:
       Type: CNAME
       Name: @ (for root domain)
       Value: ${local.config.cdn.enabled ? aws_cloudfront_distribution.website[0].domain_name : aws_s3_bucket.website.bucket}.s3-website-${local.aws_region}.amazonaws.com
       
       Type: CNAME  
       Name: www
       Value: ${local.config.cdn.enabled ? aws_cloudfront_distribution.website[0].domain_name : aws_s3_bucket.website.bucket}.s3-website-${local.aws_region}.amazonaws.com
    
    4. Wait 5-30 minutes for DNS propagation
    
    5. Test: https://${local.domain} should load your site
    
    Your site will have FREE HTTPS and global CDN! 🚀
  EOT
}

output "cost_summary" {
  description = "Monthly cost summary"
  value = {
    monthly_budget = local.config.cost.monthly_budget
    free_tier_optimized = local.config.cost.free_tier_optimized
    estimated_cost = local.config.cost.free_tier_optimized ? "0.00" : "2.50"
    free_tier_benefits = [
      "S3: 5GB storage + 20k GET requests + 2k PUT requests",
      "CloudFront: 1TB data transfer + 10M HTTP/HTTPS requests",
      "CloudWatch: Basic monitoring and 10 alarms"
    ]
  }
}

output "deployment_summary" {
  description = "Complete deployment summary"
  value = {
    site_name    = local.site_name
    domain       = local.domain
    environment  = local.environment
    aws_region   = local.aws_region
    cdn_enabled  = local.config.cdn.enabled
    cache_duration = local.config.cdn.cache_duration
    https_only   = local.config.security.https_only
    versioning   = local.config.storage.versioning
    monthly_budget = local.config.cost.monthly_budget
    repository   = local.repository
  }
}
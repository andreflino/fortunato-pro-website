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


output "certificate_validation_records" {
  description = "DNS records needed for SSL certificate validation - add these to Cloudflare"
  value = {
    for record in aws_acm_certificate.website.domain_validation_options : record.domain_name => {
      type  = record.resource_record_type
      name  = record.resource_record_name
      value = record.resource_record_value
    }
  }
}

output "ssl_certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = aws_acm_certificate.website.arn
}

output "domain_setup_instructions" {
  description = "Complete domain setup instructions with SSL"
  value = <<EOT

DOMAIN SETUP INSTRUCTIONS:

1. ADD THESE DNS RECORDS TO CLOUDFLARE:

   SSL Certificate Validation (REQUIRED FIRST):
   ${join("\n   ", [for domain, record in {
     for r in aws_acm_certificate.website.domain_validation_options : r.domain_name => {
       type  = r.resource_record_type
       name  = r.resource_record_name
       value = r.resource_record_value
     }
   } : "Type: ${record.type} | Name: ${record.name} | Value: ${record.value}"])}

2. WAIT FOR CERTIFICATE VALIDATION:
   - Certificate validation can take 5-30 minutes
   - CloudFront deployment takes 10-15 minutes after validation
   - Total setup time: 15-45 minutes

3. TEST YOUR SITE:
   - https://${local.domain}
   - https://www.${local.domain}

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
output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.website.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.website.arn
}

output "website_endpoint" {
  description = "Website endpoint URL"
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
}

output "website_domain" {
  description = "Website domain (for CloudFront)"
  value       = aws_s3_bucket_website_configuration.website.website_domain
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the bucket"
  value       = aws_s3_bucket.website.bucket_regional_domain_name
}

# CloudFront outputs
output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.website[0].id : null
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.website[0].arn : null
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.website[0].domain_name : null
}

output "cloudfront_hosted_zone_id" {
  description = "Hosted zone ID of the CloudFront distribution"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.website[0].hosted_zone_id : null
}


output "certificate_domain_name" {
  description = "Domain name of the SSL certificate"
  value       = var.domain_name != "" ? var.domain_name : null
}

# Website URL outputs
output "website_url" {
  description = "Primary website URL (custom domain if configured, otherwise CloudFront)"
  value = var.domain_name != "" && var.certificate_arn != "" ? "https://${var.domain_name}" : (
    var.enable_cloudfront ? "https://${aws_cloudfront_distribution.website[0].domain_name}" :
    "http://${aws_s3_bucket_website_configuration.website.website_endpoint}"
  )
}

output "s3_website_url" {
  description = "Direct S3 website URL (for reference)"
  value       = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}"
}

output "cloudfront_url" {
  description = "CloudFront distribution URL"
  value       = var.enable_cloudfront ? "https://${aws_cloudfront_distribution.website[0].domain_name}" : null
} 
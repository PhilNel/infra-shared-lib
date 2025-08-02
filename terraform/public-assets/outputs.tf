output "bucket_name" {
  description = "Name of the public assets S3 bucket"
  value       = aws_s3_bucket.public_assets.bucket
}

output "bucket_arn" {
  description = "ARN of the public assets S3 bucket"
  value       = aws_s3_bucket.public_assets.arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the bucket (for CloudFront origin)"
  value       = aws_s3_bucket.public_assets.bucket_regional_domain_name
}

output "origin_access_control_id" {
  description = "ID of the Origin Access Control for CloudFront (null if no CloudFront distribution ARN provided)"
  value       = var.cloudfront_distribution_arn != "" ? aws_cloudfront_origin_access_control.public_assets[0].id : null
}

output "suggested_origin_configuration" {
  description = "Suggested CloudFront origin configuration for this bucket (null if no CloudFront distribution ARN provided)"
  value = var.cloudfront_distribution_arn != "" ? {
    domain_name              = aws_s3_bucket.public_assets.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.public_assets.bucket}"
    origin_access_control_id = aws_cloudfront_origin_access_control.public_assets[0].id
  } : null
}

terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  bucket_name       = var.bucket_name
  use_custom_domain = var.domain_name != "" && var.certificate_arn != ""
}

resource "aws_s3_bucket" "website" {
  bucket = local.bucket_name

  tags = {
    Name        = local.bucket_name
    Purpose     = "Static Website Hosting"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }
}

resource "aws_cloudfront_origin_access_identity" "website" {
  count   = var.enable_cloudfront ? 1 : 0
  comment = "OAI for ${local.bucket_name}"
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = var.enable_cloudfront ? [
      # CloudFront OAI access (when CloudFront is enabled)
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.website[0].iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
      }
      ] : [
      # Public access (when CloudFront is disabled)
      {
        Sid    = "PublicReadGetObject"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  # When using CloudFront, block public access to S3
  block_public_acls       = var.enable_cloudfront
  block_public_policy     = var.enable_cloudfront
  ignore_public_acls      = var.enable_cloudfront
  restrict_public_buckets = var.enable_cloudfront
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_cloudfront_distribution" "website" {
  count = var.enable_cloudfront ? 1 : 0

  # Primary S3 origin
  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = "S3-${local.bucket_name}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.website[0].cloudfront_access_identity_path
    }
  }

  # Additional dynamic origins
  dynamic "origin" {
    for_each = var.additional_origins
    content {
      domain_name = origin.value.domain_name
      origin_id   = origin.value.origin_id

      origin_access_control_id = origin.value.origin_access_control_id

      # Custom origin configuration (when no OAC provided)
      dynamic "custom_origin_config" {
        for_each = origin.value.origin_access_control_id == null ? [1] : []
        content {
          http_port              = 80
          https_port             = 443
          origin_protocol_policy = "https-only"
          origin_ssl_protocols   = ["TLSv1.2"]
        }
      }
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = var.index_document
  price_class         = var.cloudfront_price_class

  # Custom domain configuration
  aliases = local.use_custom_domain ? [var.domain_name] : []

  default_cache_behavior {
    allowed_methods  = var.cache_behavior_config.allowed_methods
    cached_methods   = var.cache_behavior_config.cached_methods
    target_origin_id = "S3-${local.bucket_name}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = var.cache_behavior_config.min_ttl
    default_ttl            = var.cache_behavior_config.default_ttl
    max_ttl                = var.cache_behavior_config.max_ttl
    compress               = var.cache_behavior_config.compress
  }

  # Additional cache behaviors for origins with host headers or path patterns
  dynamic "ordered_cache_behavior" {
    for_each = [for origin in var.additional_origins : origin if origin.host_header != null || origin.path_pattern != null]
    content {
      path_pattern     = ordered_cache_behavior.value.path_pattern != null ? ordered_cache_behavior.value.path_pattern : "*"
      allowed_methods  = ordered_cache_behavior.value.cache_behavior.allowed_methods
      cached_methods   = ordered_cache_behavior.value.cache_behavior.cached_methods
      target_origin_id = ordered_cache_behavior.value.origin_id

      forwarded_values {
        query_string = true
        headers      = ordered_cache_behavior.value.host_header != null ? ["Host", "CloudFront-Forwarded-Proto"] : ["CloudFront-Forwarded-Proto"]
        cookies {
          forward = "none"
        }
      }

      viewer_protocol_policy = "redirect-to-https"
      min_ttl                = ordered_cache_behavior.value.cache_behavior.min_ttl
      default_ttl            = ordered_cache_behavior.value.cache_behavior.default_ttl
      max_ttl                = ordered_cache_behavior.value.cache_behavior.max_ttl
      compress               = ordered_cache_behavior.value.cache_behavior.compress
    }
  }

  # Custom error response for SPA routing
  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/${var.error_document}"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/${var.error_document}"
    error_caching_min_ttl = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    # Use custom SSL certificate if domain is configured
    acm_certificate_arn      = local.use_custom_domain ? var.certificate_arn : null
    ssl_support_method       = local.use_custom_domain ? "sni-only" : null
    minimum_protocol_version = local.use_custom_domain ? "TLSv1.2_2021" : null

    # Use default CloudFront certificate if no custom domain
    cloudfront_default_certificate = local.use_custom_domain ? null : true
  }

  tags = {
    Name        = "${local.bucket_name}-cloudfront"
    Environment = var.environment
  }
}

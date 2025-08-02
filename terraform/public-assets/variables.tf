variable "bucket_name" {
  description = "Name of the S3 bucket for public assets"
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution that will access this bucket (optional, used for bucket policy)"
  type        = string
  default     = ""
}

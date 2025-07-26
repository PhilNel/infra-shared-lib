variable "bucket_name" {
  description = "Name of the S3 bucket for static website hosting"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "index_document" {
  description = "Index document for the website"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Error document for the website (important for SPAs)"
  type        = string
  default     = "index.html"
}

variable "domain_name" {
  description = "Domain name for the website (e.g., chat.boardgamewarlock.com)"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for the custom domain"
  type        = string
  default     = ""
}

variable "enable_cloudfront" {
  description = "Enable CloudFront distribution for the website"
  type        = bool
  default     = true
}

variable "cloudfront_price_class" {
  description = "CloudFront distribution price class"
  type        = string
  default     = "PriceClass_100"
  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.cloudfront_price_class)
    error_message = "Price class must be one of: PriceClass_All, PriceClass_200, PriceClass_100."
  }
} 
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

variable "additional_origins" {
  description = "List of additional origins for the CloudFront distribution"
  type = list(object({
    domain_name              = string
    origin_id                = string
    host_header              = optional(string)
    path_pattern             = optional(string)
    origin_access_control_id = optional(string)
    cache_behavior = optional(object({
      allowed_methods = optional(list(string), ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"])
      cached_methods  = optional(list(string), ["GET", "HEAD"])
      min_ttl         = optional(number, 0)
      default_ttl     = optional(number, 3600)
      max_ttl         = optional(number, 86400)
      compress        = optional(bool, true)
    }), {})
  }))
  default = []
}

variable "cache_behavior_config" {
  description = "Configuration for the default cache behavior"
  type = object({
    allowed_methods = optional(list(string), ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"])
    cached_methods  = optional(list(string), ["GET", "HEAD"])
    min_ttl         = optional(number, 0)
    default_ttl     = optional(number, 3600)
    max_ttl         = optional(number, 86400)
    compress        = optional(bool, true)
  })
  default = {}

  validation {
    condition = alltrue([
      for method in var.cache_behavior_config.allowed_methods : contains(
        ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"],
        method
      )
    ])
    error_message = "Allowed methods must be valid HTTP methods."
  }

  validation {
    condition = alltrue([
      for method in var.cache_behavior_config.cached_methods : contains(
        ["GET", "HEAD", "OPTIONS"],
        method
      )
    ])
    error_message = "Cached methods must be GET, HEAD, or OPTIONS."
  }
} 
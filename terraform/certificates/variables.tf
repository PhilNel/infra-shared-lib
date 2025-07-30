variable "domains" {
  description = "List of domain configurations for SSL certificates"
  type = list(object({
    name                      = string
    subject_alternative_names = optional(list(string), [])
  }))

  validation {
    condition     = length(var.domains) > 0
    error_message = "At least one domain must be specified."
  }
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for DNS validation"
  type        = string
}

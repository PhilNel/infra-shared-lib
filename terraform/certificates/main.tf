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
  domain_certificates = {
    for domain in var.domains : domain.name => domain
  }
}

resource "aws_acm_certificate" "domains" {
  for_each = local.domain_certificates

  domain_name       = each.value.name
  validation_method = "DNS"

  # Support for Subject Alternative Names (SANs)
  subject_alternative_names = try(each.value.subject_alternative_names, [])

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = aws_acm_certificate.domains

  allow_overwrite = true
  name            = tolist(each.value.domain_validation_options)[0].resource_record_name
  records         = [tolist(each.value.domain_validation_options)[0].resource_record_value]
  ttl             = 60
  type            = tolist(each.value.domain_validation_options)[0].resource_record_type
  zone_id         = var.hosted_zone_id
}

resource "aws_acm_certificate_validation" "domains" {
  for_each = aws_acm_certificate.domains

  certificate_arn         = each.value.arn
  validation_record_fqdns = [aws_route53_record.cert_validation[each.key].fqdn]

  timeouts {
    create = "5m"
  }
} 
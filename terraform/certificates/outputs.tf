output "certificate_arns" {
  description = "Map of domain names to certificate ARNs"
  value = {
    for domain_name, cert in aws_acm_certificate_validation.domains : domain_name => cert.certificate_arn
  }
}

output "certificate_domains" {
  description = "Map of domain names to certificate domain names"
  value = {
    for domain_name, cert in aws_acm_certificate.domains : domain_name => cert.domain_name
  }
}
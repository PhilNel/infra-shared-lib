output "bucket_name" {
  description = "Name of the artefacts bucket"
  value       = aws_s3_bucket.artefacts.id
}

output "bucket_arn" {
  description = "ARN of the artefacts bucket"
  value       = aws_s3_bucket.artefacts.arn
}
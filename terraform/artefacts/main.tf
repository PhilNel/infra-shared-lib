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
  bucket_name = var.bucket_name
}

resource "aws_s3_bucket" "artefacts" {
  bucket = local.bucket_name

  tags = {
    Name = local.bucket_name
  }
}

# Enable versioning for the bucket
resource "aws_s3_bucket_versioning" "artefacts" {
  bucket = aws_s3_bucket.artefacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "artefacts" {
  bucket = aws_s3_bucket.artefacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "artefacts" {
  bucket = aws_s3_bucket.artefacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
  
  backend "s3" {
    # Backend configuration will be provided via init command
    # Standard naming: {account-id}-terraform-state-{region}
    # Example: 123456789012-terraform-state-us-east-1
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Environment = "infrastructure"
      Project     = "backstage-template"
    }
  }
}

# Example S3 bucket resource
resource "aws_s3_bucket" "example" {
  bucket = "${var.aws_account_id}-example-bucket-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "Example Bucket"
    Description = "Created by Backstage Terraform template"
  }
}

resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

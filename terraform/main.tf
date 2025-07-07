terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    # Backend configuration will be provided via init command
  }
}

provider "aws" {
  region = var.aws_region
}

# Example S3 bucket
resource "aws_s3_bucket" "example" {
  bucket = "${var.aws_account_id}-example-bucket-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

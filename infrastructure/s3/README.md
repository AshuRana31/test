# AWS S3 Bucket Infrastructure

This directory contains Terraform configuration for creating an AWS S3 bucket with secure defaults.

## Features

- Creates an S3 bucket with the specified name
- Blocks all public access by default
- Enables server-side encryption using AES-256
- Optional versioning support
- Configurable tags
- Region-specific deployment

## Configuration

The following variables can be configured:

- `bucket_name`: Name of the S3 bucket (must be globally unique)
- `region`: AWS region where the bucket will be created
- `environment`: Deployment environment (dev, staging, prod)
- `versioning`: Enable versioning for the S3 bucket (default: false)
- `tags`: Additional tags for the S3 bucket (default: {})

## Security Features

1. Public Access Block
   - Blocks all public ACLs
   - Blocks public policy
   - Ignores public ACLs
   - Restricts public bucket policies

2. Encryption
   - Server-side encryption enabled by default
   - Uses AES-256 encryption algorithm

## Prerequisites

- AWS credentials configured
- Terraform >= 1.0
- AWS provider ~> 4.0

## Usage

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review the plan:
   ```bash
   terraform plan
   ```

3. Apply the configuration:
   ```bash
   terraform apply
   ```

## Outputs

- `bucket_name`: Name of the created S3 bucket
- `bucket_arn`: ARN of the created S3 bucket
- `versioning_enabled`: Whether versioning is enabled for the bucket
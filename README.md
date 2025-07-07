# Terraform infrastructure with GitHub Actions

This repository contains Terraform infrastructure with GitHub Actions CI/CD pipeline.

## Setup

1. **AWS OIDC Setup**: Configure AWS OIDC provider for GitHub Actions
2. **S3 Backend**: Create S3 bucket for Terraform state
3. **DynamoDB Table**: Create DynamoDB table for state locking

## Usage

1. Add your Terraform files to the `terraform/` directory
2. Create a pull request - this will run `terraform plan`
3. Merge to main - this will run `terraform apply`

## Configuration

- **AWS Account**: 038751964618
- **AWS Region**: us-east-1
- **Team**: Platform Team

## Directory Structure

```
terraform/
├── main.tf
├── variables.tf
└── outputs.tf
```

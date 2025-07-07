#!/bin/bash

# AWS Terraform Backend Setup Script
# This script creates the S3 bucket and DynamoDB table needed for Terraform remote state
# 
# Prerequisites:
# - AWS CLI configured with appropriate permissions
# - IAM permissions for S3 and DynamoDB operations

set -e

# Configuration - Standard naming conventions
AWS_ACCOUNT_ID="038751964618"
AWS_REGION="us-east-1"
BUCKET_NAME="${AWS_ACCOUNT_ID}-terraform-state-${AWS_REGION}"
DYNAMODB_TABLE="${AWS_ACCOUNT_ID}-terraform-locks"

echo "🚀 Setting up Terraform backend infrastructure"
echo "📋 Configuration:"
echo "   AWS Account ID: $AWS_ACCOUNT_ID"
echo "   AWS Region: $AWS_REGION"
echo "   S3 Bucket: $BUCKET_NAME"
echo "   DynamoDB Table: $DYNAMODB_TABLE"
echo ""

# Verify AWS CLI is configured
echo "🔍 Verifying AWS credentials..."
if ! aws sts get-caller-identity &>/dev/null; then
    echo "❌ AWS CLI is not configured or you don't have permissions"
    echo "   Please run 'aws configure' or set up your AWS credentials"
    exit 1
fi

CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
if [ "$CURRENT_ACCOUNT" != "$AWS_ACCOUNT_ID" ]; then
    echo "⚠️  Warning: Current AWS account ($CURRENT_ACCOUNT) doesn't match expected account ($AWS_ACCOUNT_ID)"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "✅ AWS credentials verified"
echo ""

# Create S3 bucket for Terraform state
echo "📦 Setting up S3 bucket: $BUCKET_NAME"
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "✅ S3 bucket already exists"
else
    echo "   Creating S3 bucket..."
    aws s3 mb "s3://$BUCKET_NAME" --region "$AWS_REGION"
    echo "✅ S3 bucket created"
fi

# Configure bucket settings
echo "🔧 Configuring S3 bucket settings..."

# Enable versioning
echo "   Enabling versioning..."
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

# Enable server-side encryption
echo "   Enabling server-side encryption..."
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                },
                "BucketKeyEnabled": true
            }
        ]
    }'

# Block public access
echo "   Blocking public access..."
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "✅ S3 bucket configured"
echo ""

# Create DynamoDB table for state locking
echo "🔐 Setting up DynamoDB table: $DYNAMODB_TABLE"
if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION" &>/dev/null; then
    echo "✅ DynamoDB table already exists"
else
    echo "   Creating DynamoDB table..."
    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --region "$AWS_REGION" \
        --tags Key=Purpose,Value=TerraformStateLocking Key=ManagedBy,Value=BackstageTemplate
    
    echo "   Waiting for DynamoDB table to be active..."
    aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION"
    echo "✅ DynamoDB table created and active"
fi

echo ""
echo "🎉 Terraform backend setup complete!"
echo ""
echo "📋 Backend Configuration Summary:"
echo "   S3 Bucket: $BUCKET_NAME"
echo "   DynamoDB Table: $DYNAMODB_TABLE"
echo "   Region: $AWS_REGION"
echo ""
echo "🔧 Terraform Backend Configuration:"
echo "terraform {"
echo "  backend \"s3\" {"
echo "    bucket         = \"$BUCKET_NAME\""
echo "    key            = \"infrastructure/terraform.tfstate\""
echo "    region         = \"$AWS_REGION\""
echo "    dynamodb_table = \"$DYNAMODB_TABLE\""
echo "  }"
echo "}"
echo ""
echo "🚀 Next Steps:"
echo "1. Ensure AWS OIDC is configured for GitHub Actions"
echo "2. Run 'terraform init' in your terraform directory"
echo "3. Create a pull request to test the GitHub Actions workflow"

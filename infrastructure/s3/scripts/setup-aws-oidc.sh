#!/bin/bash

# AWS OIDC Setup Script for GitHub Actions
# This script sets up the necessary AWS resources for GitHub Actions OIDC authentication

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    print_error "jq is not installed. Please install it first."
    exit 1
fi

# Get input parameters
read -p "Enter your GitHub organization/username: " GITHUB_ORG
read -p "Enter your GitHub repository name: " GITHUB_REPO
read -p "Enter your AWS account ID: " AWS_ACCOUNT_ID
read -p "Enter AWS region [us-east-1]: " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}

# Validate inputs
if [[ -z "$GITHUB_ORG" || -z "$GITHUB_REPO" || -z "$AWS_ACCOUNT_ID" ]]; then
    print_error "All parameters are required!"
    exit 1
fi

print_header "Setting up AWS OIDC for GitHub Actions"
echo "GitHub Repository: $GITHUB_ORG/$GITHUB_REPO"
echo "AWS Account: $AWS_ACCOUNT_ID"
echo "AWS Region: $AWS_REGION"
echo ""

# Step 1: Create OIDC Identity Provider
print_status "Creating OIDC Identity Provider..."

OIDC_PROVIDER_ARN="arn:aws:iam::$AWS_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"

if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_PROVIDER_ARN" &>/dev/null; then
    print_warning "OIDC provider already exists"
else
    aws iam create-open-id-connect-provider \
        --url https://token.actions.githubusercontent.com \
        --client-id-list sts.amazonaws.com \
        --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
        --region "$AWS_REGION"
    print_status "OIDC provider created successfully"
fi

# Step 2: Create IAM Role Trust Policy
print_status "Creating IAM role trust policy..."

TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "$OIDC_PROVIDER_ARN"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:$GITHUB_ORG/$GITHUB_REPO:*"
        }
      }
    }
  ]
}
EOF
)

# Step 3: Create IAM Role
print_status "Creating GitHubActionsRole..."

ROLE_NAME="GitHubActionsRole"

if aws iam get-role --role-name "$ROLE_NAME" &>/dev/null; then
    print_warning "Role $ROLE_NAME already exists, updating trust policy..."
    echo "$TRUST_POLICY" > /tmp/trust-policy.json
    aws iam update-assume-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-document file:///tmp/trust-policy.json
    rm /tmp/trust-policy.json
else
    echo "$TRUST_POLICY" > /tmp/trust-policy.json
    aws iam create-role \
        --role-name "$ROLE_NAME" \
        --assume-role-policy-document file:///tmp/trust-policy.json \
        --description "Role for GitHub Actions OIDC authentication"
    rm /tmp/trust-policy.json
    print_status "Role $ROLE_NAME created successfully"
fi

# Step 4: Create IAM Policy for Terraform Operations
print_status "Creating IAM policy for Terraform operations..."

POLICY_NAME="GitHubActionsTerraformPolicy"
POLICY_DOCUMENT=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:GetBucketLocation",
        "s3:GetBucketVersioning",
        "s3:GetBucketEncryption",
        "s3:GetBucketPublicAccessBlock",
        "s3:PutBucketVersioning",
        "s3:PutBucketEncryption",
        "s3:PutBucketPublicAccessBlock",
        "s3:PutBucketTagging",
        "s3:GetBucketTagging",
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:CreateTable",
        "dynamodb:DeleteTable",
        "dynamodb:DescribeTable",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:UpdateItem"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:GetRole",
        "iam:PassRole"
      ],
      "Resource": "*"
    }
  ]
}
EOF
)

# Check if policy exists
POLICY_ARN="arn:aws:iam::$AWS_ACCOUNT_ID:policy/$POLICY_NAME"

if aws iam get-policy --policy-arn "$POLICY_ARN" &>/dev/null; then
    print_warning "Policy $POLICY_NAME already exists, creating new version..."
    echo "$POLICY_DOCUMENT" > /tmp/policy.json
    aws iam create-policy-version \
        --policy-arn "$POLICY_ARN" \
        --policy-document file:///tmp/policy.json \
        --set-as-default
    rm /tmp/policy.json
else
    echo "$POLICY_DOCUMENT" > /tmp/policy.json
    aws iam create-policy \
        --policy-name "$POLICY_NAME" \
        --policy-document file:///tmp/policy.json \
        --description "Policy for GitHub Actions Terraform operations"
    rm /tmp/policy.json
    print_status "Policy $POLICY_NAME created successfully"
fi

# Step 5: Attach Policy to Role
print_status "Attaching policy to role..."

aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "$POLICY_ARN"

print_status "Policy attached successfully"

# Step 6: Output configuration details
print_header "Setup Complete!"
echo ""
echo "📋 Configuration Summary:"
echo "========================="
echo "OIDC Provider ARN: $OIDC_PROVIDER_ARN"
echo "IAM Role ARN: arn:aws:iam::$AWS_ACCOUNT_ID:role/$ROLE_NAME"
echo "IAM Policy ARN: $POLICY_ARN"
echo ""
echo "🔧 GitHub Repository Secrets to Set:"
echo "===================================="
echo "AWS_ACCOUNT_ID: $AWS_ACCOUNT_ID"
echo ""
echo "🔧 GitHub Repository Variables to Set:"
echo "======================================"
echo "AWS_REGION: $AWS_REGION"
echo ""
echo "✅ Next Steps:"
echo "=============="
echo "1. Set the above secrets and variables in your GitHub repository"
echo "2. Run the 'Setup Terraform Backend' workflow in GitHub Actions"
echo "3. Create a pull request with Terraform code to test the setup"
echo ""
echo "🔗 Useful Links:"
echo "==============="
echo "GitHub Repository: https://github.com/$GITHUB_ORG/$GITHUB_REPO"
echo "AWS IAM Console: https://console.aws.amazon.com/iam/"
echo "GitHub Actions: https://github.com/$GITHUB_ORG/$GITHUB_REPO/actions"

print_status "AWS OIDC setup completed successfully!"

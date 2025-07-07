# 🚀 GitHub Actions Setup Guide for Terraform S3 Deployment

This guide will help you set up the necessary AWS infrastructure and GitHub configuration to run Terraform plans on pull requests and apply changes on merge.

## 📋 Prerequisites

- AWS Account with appropriate permissions
- GitHub repository with Actions enabled
- AWS CLI configured locally (for initial setup)

## 🔧 Step 1: Create AWS Infrastructure for GitHub Actions

### 1.1 Create OIDC Identity Provider

```bash
# Create the OIDC identity provider for GitHub Actions
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --client-id-list sts.amazonaws.com
```

### 1.2 Create IAM Role for GitHub Actions

Create a file `github-actions-trust-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::038751964618:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:*"
        }
      }
    }
  ]
}
```

Create the IAM role:

```bash
# Replace YOUR_GITHUB_USERNAME and YOUR_REPO_NAME with actual values
aws iam create-role \
  --role-name GitHubActionsRole \
  --assume-role-policy-document file://github-actions-trust-policy.json
```

### 1.3 Create IAM Policy for S3 Operations

Create a file `s3-terraform-policy.json`:

```json
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
        "s3:GetBucketAcl",
        "s3:GetBucketCORS",
        "s3:GetBucketWebsite",
        "s3:GetBucketLogging",
        "s3:GetBucketNotification",
        "s3:GetBucketPolicy",
        "s3:GetBucketRequestPayment",
        "s3:GetBucketTagging",
        "s3:ListBucket",
        "s3:PutBucketVersioning",
        "s3:PutBucketAcl",
        "s3:PutBucketCORS",
        "s3:PutBucketWebsite",
        "s3:PutBucketLogging",
        "s3:PutBucketNotification",
        "s3:PutBucketPolicy",
        "s3:PutBucketRequestPayment",
        "s3:PutBucketTagging",
        "s3:PutEncryptionConfiguration",
        "s3:PutBucketPublicAccessBlock",
        "s3:GetBucketPublicAccessBlock",
        "s3:GetEncryptionConfiguration"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::038751964618-terraform-state-*/*",
        "arn:aws:s3:::test-backstage-ashurana31/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:038751964618:table/038751964618-terraform-locks"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    }
  ]
}
```

Attach the policy to the role:

```bash
# Create the policy
aws iam create-policy \
  --policy-name S3TerraformPolicy \
  --policy-document file://s3-terraform-policy.json

# Attach the policy to the role
aws iam attach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::038751964618:policy/S3TerraformPolicy
```

### 1.4 Create Terraform State Backend

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://038751964618-terraform-state-us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket 038751964618-terraform-state-us-east-1 \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name 038751964618-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

## 🔐 Step 2: Configure GitHub Repository

### 2.1 Repository Settings

1. Go to your GitHub repository
2. Navigate to **Settings** → **Actions** → **General**
3. Ensure **Actions permissions** is set to "Allow all actions and reusable workflows"

### 2.2 Environment Configuration

1. Go to **Settings** → **Environments**
2. Create environments:
   - `dev`
   - `staging` (optional)
   - `prod` (optional)
   - `dev-destroy` (for destroy operations)

3. For each environment, configure:
   - **Required reviewers** (recommended for prod)
   - **Wait timer** (optional)
   - **Deployment branches** (restrict to main/master for prod)

### 2.3 Repository Secrets (Optional)

If you prefer using secrets instead of template variables, add these to **Settings** → **Secrets and variables** → **Actions**:

- `AWS_ACCOUNT_ID`: Your AWS account ID
- `AWS_REGION`: Your preferred AWS region
- `TERRAFORM_STATE_BUCKET`: Name of your Terraform state bucket
- `TERRAFORM_LOCK_TABLE`: Name of your DynamoDB lock table

## 🧪 Step 3: Test the Setup

### 3.1 Create a Test Pull Request

1. Create a new branch: `git checkout -b test-terraform-pipeline`
2. Make a small change to any file in the `infrastructure/` directory
3. Commit and push: `git add . && git commit -m "test: trigger terraform pipeline" && git push origin test-terraform-pipeline`
4. Create a pull request

### 3.2 Verify Pipeline Execution

The pipeline should:

1. ✅ **Trigger automatically** when PR is created
2. ✅ **Run terraform plan** successfully
3. ✅ **Comment on PR** with plan results
4. ✅ **Show green checkmark** if plan succeeds

### 3.3 Test Apply (Optional)

1. Merge the test PR to main branch
2. Verify that terraform apply runs automatically
3. Check AWS console to confirm resources are created

## 🔍 Troubleshooting

### Common Issues

#### 1. "Error assuming role"
- Verify OIDC provider is created correctly
- Check trust policy has correct repository name
- Ensure role ARN is correct in workflow

#### 2. "Access denied" errors
- Verify IAM policy permissions
- Check if resources already exist with different ownership
- Ensure AWS account ID is correct

#### 3. "Backend initialization failed"
- Verify S3 bucket exists and is accessible
- Check DynamoDB table exists
- Ensure bucket name follows naming convention

#### 4. "Plan fails with validation errors"
- Check Terraform syntax in `.tf` files
- Verify all required variables are provided
- Ensure AWS provider configuration is correct

### Debug Commands

```bash
# Check if OIDC provider exists
aws iam list-open-id-connect-providers

# Verify role exists
aws iam get-role --role-name GitHubActionsRole

# Check S3 bucket
aws s3 ls s3://038751964618-terraform-state-us-east-1

# Verify DynamoDB table
aws dynamodb describe-table --table-name 038751964618-terraform-locks
```

## 📚 Additional Resources

- [GitHub Actions OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Terraform S3 Backend](https://www.terraform.io/docs/language/settings/backends/s3.html)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

## 🎯 Next Steps

1. **Customize the pipeline** for your specific needs
2. **Add more environments** (staging, prod) if needed
3. **Implement approval workflows** for production deployments
4. **Add notification integrations** (Slack, Teams, etc.)
5. **Set up monitoring** for deployed resources

---

**🎉 Congratulations!** Your Terraform CI/CD pipeline is now ready to run plans on PRs and apply changes on merge!

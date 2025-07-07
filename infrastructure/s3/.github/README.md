# GitHub Actions for Terraform Deployment

This repository contains GitHub Actions workflows for automated Terraform deployment to AWS using OIDC authentication.

## 🏗️ Architecture Overview

```
Backstage Template → GitHub PR → GitHub Actions → AWS (via OIDC) → Terraform Deploy
```

## 📋 Prerequisites

### 1. AWS OIDC Setup

You need to set up AWS OIDC identity provider and IAM role for GitHub Actions:

#### Create OIDC Identity Provider
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

#### Create IAM Role for GitHub Actions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT-ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR-ORG/YOUR-REPO:*"
        }
      }
    }
  ]
}
```

#### IAM Policy for GitHubActionsRole
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "dynamodb:*",
        "iam:GetRole",
        "iam:PassRole"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::YOUR-TERRAFORM-STATE-BUCKET",
        "arn:aws:s3:::YOUR-TERRAFORM-STATE-BUCKET/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/terraform-state-lock"
    }
  ]
}
```

### 2. Repository Secrets

Set up the following secrets in your GitHub repository:

#### Required Secrets
- `AWS_ACCOUNT_ID`: Your AWS account ID
- `TERRAFORM_STATE_BUCKET`: S3 bucket for Terraform state (auto-created by setup workflow)
- `TERRAFORM_LOCK_TABLE`: DynamoDB table for state locking (auto-created by setup workflow)

#### Optional Multi-Environment Secrets
- `AWS_ACCOUNT_ID_DEV`: Development account ID
- `AWS_ACCOUNT_ID_STAGING`: Staging account ID  
- `AWS_ACCOUNT_ID_PROD`: Production account ID

### 3. Repository Variables

Set up the following variables in your GitHub repository:

- `AWS_REGION`: Default AWS region (e.g., `us-east-1`)
- `AWS_REGION_DEV`: Development region (optional)
- `AWS_REGION_STAGING`: Staging region (optional)
- `AWS_REGION_PROD`: Production region (optional)

## 🚀 Workflows

### 1. Setup Terraform Backend (`setup-terraform-backend.yml`)

**Purpose**: Creates S3 bucket and DynamoDB table for Terraform state management.

**Trigger**: Manual workflow dispatch

**Usage**:
1. Go to Actions tab in GitHub
2. Select "Setup Terraform Backend"
3. Click "Run workflow"
4. Provide:
   - AWS Region
   - S3 bucket name (globally unique)
   - DynamoDB table name

**What it does**:
- Creates S3 bucket with versioning and encryption
- Creates DynamoDB table for state locking
- Updates repository secrets automatically

### 2. Terraform Deploy (`terraform-deploy.yml`)

**Purpose**: Standard Terraform deployment workflow.

**Triggers**:
- Pull Request (runs `terraform plan`)
- Push to main/master (runs `terraform apply`)
- Manual dispatch (plan/apply/destroy)

**Features**:
- Automatic PR comments with plan output
- Terraform validation and formatting checks
- Secure state management
- Output capture and display

### 3. Multi-Environment Deploy (`terraform-multi-env.yml`)

**Purpose**: Advanced multi-environment deployment with branch-based targeting.

**Environment Mapping**:
- `main` branch → `prod` environment
- `develop` branch → `staging` environment
- `release/*` branches → `staging` environment
- Other branches → `dev` environment

**Features**:
- Automatic environment detection
- Multi-account support
- Environment-specific configurations
- GitHub Environment protection rules

## 🔄 Deployment Flow

### Standard Flow
1. **Backstage generates PR** with Terraform code
2. **PR triggers plan** - GitHub Actions runs `terraform plan`
3. **Plan results commented** on PR automatically
4. **Review and merge** PR after reviewing plan
5. **Merge triggers apply** - GitHub Actions runs `terraform apply`
6. **Infrastructure deployed** to AWS

### Multi-Environment Flow
1. **Feature branch** → `dev` environment (auto-deploy)
2. **Develop branch** → `staging` environment (auto-deploy)
3. **Main branch** → `prod` environment (with approval)

## 🛡️ Security Features

- **OIDC Authentication**: No long-lived AWS credentials
- **Least Privilege**: IAM roles with minimal required permissions
- **State Encryption**: Terraform state encrypted at rest
- **State Locking**: Prevents concurrent modifications
- **Environment Protection**: GitHub environments with approval rules
- **Audit Trail**: All actions logged and traceable

## 📊 Monitoring and Troubleshooting

### View Deployment Status
- Check Actions tab for workflow runs
- Review PR comments for plan output
- Monitor AWS CloudTrail for API calls

### Common Issues

#### 1. OIDC Authentication Failed
```
Error: Could not assume role with OIDC
```
**Solution**: Verify OIDC provider and IAM role trust policy

#### 2. State Bucket Access Denied
```
Error: Failed to get existing workspaces
```
**Solution**: Check IAM permissions for S3 bucket access

#### 3. DynamoDB Lock Table Not Found
```
Error: ResourceNotFoundException: Table not found
```
**Solution**: Run the setup-terraform-backend workflow

## 🔧 Customization

### Adding New Environments
1. Add environment-specific secrets/variables
2. Update environment mapping in workflows
3. Create GitHub Environment with protection rules

### Custom Terraform Modules
1. Add module source to `main.tf`
2. Update variable definitions
3. Modify workflow matrix for new paths

### Advanced State Management
```yaml
# Custom backend configuration
-backend-config="bucket="
-backend-config="key=custom/path/terraform.tfstate"
-backend-config="region="
-backend-config="encrypt=true"
-backend-config="dynamodb_table="
```

## 📚 Best Practices

1. **Always review plans** before merging PRs
2. **Use environment protection** for production deployments
3. **Monitor state file size** and clean up old versions
4. **Rotate OIDC thumbprints** regularly
5. **Use semantic versioning** for releases
6. **Tag resources** consistently for cost tracking
7. **Implement drift detection** for production environments

## 🆘 Support

For issues with:
- **Backstage templates**: Check template validation
- **GitHub Actions**: Review workflow logs
- **AWS permissions**: Verify IAM roles and policies
- **Terraform state**: Check S3 bucket and DynamoDB table

## 📖 Additional Resources

- [AWS OIDC Setup Guide](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Terraform Backend Configuration](https://www.terraform.io/docs/language/settings/backends/s3.html)
- [GitHub Actions Security](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)

# Terraform infrastructure with GitHub Actions

This repository contains Terraform infrastructure with GitHub Actions CI/CD pipeline.

## ⚠️ Prerequisites

**Before using this template, ensure the following are set up:**

### 1. AWS OIDC Provider for GitHub Actions
Set up AWS OIDC authentication for GitHub Actions. See `AWS_SETUP.md` for detailed instructions.

### 2. Terraform Backend Infrastructure
Run the setup script to create the required AWS resources:

```bash
# Make the script executable
chmod +x scripts/setup-aws-backend.sh

# Run the setup script
./scripts/setup-aws-backend.sh
```

This creates:
- **S3 Bucket**: `038751964618-terraform-state-us-east-1`
- **DynamoDB Table**: `038751964618-terraform-locks`

## 📋 Configuration

- **AWS Account**: `038751964618`
- **AWS Region**: `us-east-1`
- **Team**: `Platform Team`

## 🔄 GitHub Actions Workflow

The workflow automatically:

### On Pull Request:
1. ✅ Validates Terraform configuration
2. 📋 Runs `terraform plan`
3. 💬 Comments on PR with plan results

### On Merge to Main:
1. 🚀 Runs `terraform apply`
2. 📦 Deploys infrastructure changes

### Manual Trigger:
- Use GitHub Actions "workflow_dispatch" to run manually

## 📁 Directory Structure

```
terraform/
├── main.tf          # Main Terraform configuration
├── variables.tf     # Variable definitions
└── outputs.tf       # Output definitions

.github/workflows/
└── terraform.yml    # GitHub Actions CI/CD workflow

scripts/
└── setup-aws-backend.sh  # Backend setup script (run this first!)
```

## 🛠️ Local Development

To work with Terraform locally:

```bash
cd terraform

# Initialize with backend configuration
terraform init \
  -backend-config="bucket=038751964618-terraform-state-us-east-1" \
  -backend-config="key=infrastructure/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=038751964618-terraform-locks"

# Plan changes
terraform plan

# Apply changes (be careful!)
terraform apply
```

## 🔧 Troubleshooting

### "S3 bucket does not exist" Error
1. ✅ Run the setup script: `./scripts/setup-aws-backend.sh`
2. ✅ Verify the bucket name matches: `038751964618-terraform-state-us-east-1`

### AWS Authentication Issues
1. ✅ Ensure AWS OIDC is properly configured (see `AWS_SETUP.md`)
2. ✅ Check that the GitHub repository URL matches the OIDC trust policy
3. ✅ Verify the IAM role `GitHubActionsRole` exists and has necessary permissions

### GitHub Actions Workflow Fails
1. ✅ Check that prerequisites are completed
2. ✅ Verify AWS credentials are working
3. ✅ Ensure the repository has the required secrets/permissions

## 🚀 Getting Started

1. **Complete Prerequisites** (see above)
2. **Create a Pull Request** with Terraform changes
3. **Review the Plan** in the PR comments
4. **Merge to Deploy** your infrastructure

## 📚 Additional Resources

- `AWS_SETUP.md` - Detailed AWS OIDC setup instructions
- `scripts/setup-aws-backend.sh` - Backend infrastructure setup
- `.github/workflows/terraform.yml` - CI/CD workflow configuration

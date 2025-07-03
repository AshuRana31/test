# AWS Multi-Environment Networking Infrastructure

This repository contains a single Terraform configuration for creating standardized AWS networking infrastructure across multiple environments using environment-specific `.tfvars` files.

## 📋 Project Information

- **Project**: {{ values.projectName }}
- **Client**: {{ values.clientName }}
- **Description**: {{ values.description }}
- **Region**: {{ values.region }}
- **Architecture**: {{ values.networkTier | title }}

## 🏗️ Architecture Overview

This infrastructure creates a standardized VPC setup with the following components:

### Network Tiers

- **Basic**: Public subnets only (suitable for simple web applications)
- **Standard**: Public + Private subnets (recommended for most applications)
- **Advanced**: Public + Private + Database subnets (for complex applications with databases)

### Environment Configuration


#### Development Environment
- **VPC CIDR**: `{{ values.devVpcCidr | default('10.0.0.0/16') }}`
- **Availability Zones**: `{{ values.devAvailabilityZones | default(2) }}`
- **NAT Gateway**: {{ values.devNatGateway and '✅ Enabled' or '❌ Disabled' }}






## 🌐 Network Components

### Subnets
- **Public Subnets**: Internet-accessible subnets for load balancers, NAT gateways
- **Private Subnets**: Internal subnets for application servers, containers


### Gateways & Routing
- **Internet Gateway**: Provides internet access to public subnets
- **NAT Gateways**: Enable outbound internet access for private subnets (environment-specific)
- **Route Tables**: Separate routing for each subnet tier

### Security & Monitoring

- **VPC Flow Logs**: Network traffic logging for security and troubleshooting (Production)



## 📁 Directory Structure

```
.
├── main.tf                    # Main Terraform configuration (single file)
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── terraform.tfvars.example   # Example configuration
├── development.tfvars         # Development environment variables
├── staging.tfvars             # Staging environment variables
├── uat.tfvars                 # UAT environment variables
├── production.tfvars          # Production environment variables
└── README.md                  # This file
```

## 🚀 Getting Started

### Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **S3 bucket** for Terraform state storage (recommended)
4. **DynamoDB table** for state locking (recommended)

### Step 1: Configure Backend

Edit the backend configuration in `main.tf`:

```hcl
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "networking/terraform.tfstate"
  region         = "{{ values.region }}"
  dynamodb_table = "terraform-state-lock"
  encrypt        = true
}
```

### Step 2: Review Configuration

Check the environment-specific `.tfvars` files and adjust values as needed:
- `development.tfvars` - Development environment settings



### Step 3: Deploy Infrastructure

Deploy each environment using the appropriate `.tfvars` file:

```bash

# Development Environment
terraform init
terraform plan -var-file="development.tfvars"
terraform apply -var-file="development.tfvars"





```

### Alternative: Using Terraform Workspaces

You can also use Terraform workspaces for environment separation:

```bash

# Create and switch to development workspace
terraform workspace new development
terraform plan -var-file="development.tfvars"
terraform apply -var-file="development.tfvars"





```

## 🔧 Configuration Options

### Environment Variables

Each environment is configured through its respective `.tfvars` file:

| Variable | Description | Example |
|----------|-------------|---------|
| `project_name` | Project identifier | `{{ values.projectName }}` |
| `client_name` | Client/organization name | `{{ values.clientName }}` |
| `environment` | Environment name | `development`, `production` |
| `region` | AWS region | `{{ values.region }}` |
| `availability_zones` | Number of AZs to use | `{{ values.availabilityZones }}` |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `network_tier` | Architecture complexity | `{{ values.networkTier }}` |
| `enable_nat_gateway` | Enable NAT Gateway | `true`/`false` |
| `enable_vpc_flow_logs` | Enable VPC Flow Logs | `true`/`false` |
| `enable_vpc_endpoints` | Enable VPC endpoints | `true`/`false` |

### VPC CIDR Blocks

| Environment | CIDR Block | IP Range |
|-------------|------------|----------|


## 💰 Cost Estimation

### Monthly Costs (USD)

| Component | Cost per Unit | Total |
|-----------|---------------|-------|


| NAT Gateways | $45/month × {{ nat_count }} envs × {{ values.availabilityZones }} AZs | ~NaN/month |



| VPC Flow Logs | Variable (traffic-based) | ~$10-50/month |


> **Note**: Costs are estimates and may vary based on actual usage, data transfer, and AWS pricing changes.

## 🔧 Usage Examples


### Deploy Development Environment
```bash
terraform init
terraform plan -var-file="development.tfvars"
terraform apply -var-file="development.tfvars"
```






### Switch Between Environments
```bash
# View current resources
terraform show

# Plan changes for different environment
terraform plan -var-file="staging.tfvars"

# Apply changes
terraform apply -var-file="staging.tfvars"
```

### Destroy Environment
```bash
terraform destroy -var-file="development.tfvars"
```

## 🔒 Security Considerations

### Network Security
- Private subnets have no direct internet access
- NAT Gateways provide controlled outbound access
- Security groups and NACLs can be added as needed

### Access Control
- Use IAM roles and policies for resource access
- Consider AWS Systems Manager Session Manager for secure instance access
- Implement least-privilege access principles

### Monitoring

- VPC Flow Logs enabled for production environment

- CloudWatch metrics available for all network components
- Consider enabling AWS Config for compliance monitoring

## 🔧 Customization

### Adding New Environments

1. Create a new `.tfvars` file (e.g., `preprod.tfvars`)
2. Copy configuration from an existing environment file
3. Update the `environment` variable and other settings
4. Deploy using `terraform apply -var-file="preprod.tfvars"`

### Modifying Network Architecture

To change the network tier:
1. Update `network_tier` in the appropriate `.tfvars` file
2. Run `terraform plan -var-file="environment.tfvars"` to review changes
3. Apply changes with `terraform apply -var-file="environment.tfvars"`

### Adding VPC Endpoints

Set `enable_vpc_endpoints = true` in your environment configuration to add:
- S3 Gateway Endpoint (no additional cost)
- ECR Interface Endpoints (for container workloads)

## 📊 Outputs

After deployment, Terraform will output important resource information:

- VPC ID and CIDR block
- Subnet IDs for each tier
- Route table IDs
- NAT Gateway IPs
- VPC endpoint IDs

Use these outputs in other Terraform configurations or applications.

## 🆘 Troubleshooting

### Common Issues

1. **CIDR Conflicts**: Ensure VPC CIDR blocks don't overlap between environments
2. **State Conflicts**: Use different state files or workspaces for each environment
3. **AZ Availability**: Some regions may not have all requested availability zones
4. **Resource Limits**: Check AWS service limits for VPCs, subnets, and NAT gateways

### Getting Help

1. Check Terraform plan output for detailed error messages
2. Review AWS CloudTrail logs for API call failures
3. Verify IAM permissions for Terraform execution
4. Consult AWS documentation for service-specific requirements

## 📚 Additional Resources

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Pricing Calculator](https://calculator.aws/)

## 🤝 Contributing

To modify this infrastructure:

1. Make changes to the Terraform configuration
2. Test in a development environment first
3. Update documentation as needed
4. Follow your organization's change management process

---

**Generated by**: Backstage AWS Networking Template  
**Date**: {{ "now" | date("YYYY-MM-DD") }}  
**Version**: 2.0 (Single File Architecture)
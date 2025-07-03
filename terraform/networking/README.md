# Advanced AWS Multi-Environment Networking Infrastructure

This repository contains a comprehensive Terraform configuration for creating advanced AWS networking infrastructure across multiple environments with dynamic configuration and extensive customization options.

## 📋 Project Information

- **Project**: {{ values.projectName }}
- **Client**: {{ values.clientName }}
- **Description**: {{ values.description }}
- **Technical Contact**: {{ values.technicalContact }}
- **Cost Center**: {{ values.costCenter }}
- **Deployment Timeline**: {{ values.deploymentTimeline }}
- **Region**: {{ values.region }}
- **Availability Zones**: {{ values.availabilityZones }}

## 🏗️ Architecture Overview

This infrastructure creates a highly customizable VPC setup with advanced networking features:

### Network Architecture
- **Public Subnets**: {{ values.publicSubnetCount }} subnets for internet-facing resources
- **Private Subnets**: {{ values.privateSubnetCount }} subnets for application servers
- **Database Subnets**: {{ values.databaseSubnetCount }} subnets for database resources
- **Subnet Sizing Strategy**: {{ values.subnetSizingStrategy }}
- **IPv6 Support**: {{ values.enableIpv6 and '✅ Enabled' or '❌ Disabled' }}

### Gateway Configuration
- **Internet Gateway**: {{ values.createInternetGateway and '✅ Enabled' or '❌ Disabled' }}
- **NAT Gateway Strategy**: {{ values.natGatewayStrategy }}
- **NAT Gateway Type**: {{ values.natGatewayType }}
- **VPN Gateway**: {{ values.enableVpnGateway and '✅ Enabled' or '❌ Disabled' }}

### Environment Configuration


#### {{ env | title }} Environment

- **Account ID**: {{ values.devAccountId or 'Not specified' }}
- **VPC CIDR**: `{{ values.devVpcCidr | default('10.0.0.0/16') }}`
- **DNS Hostnames**: {{ values.devDnsHostnames and '✅ Enabled' or '❌ Disabled' }}
- **DNS Resolution**: {{ values.devDnsResolution and '✅ Enabled' or '❌ Disabled' }}
- **VPC Flow Logs**: {{ values.devVpcFlowLogs and '✅ Enabled' or '❌ Disabled' }}



## 🔒 Advanced Security Features

### Security Groups
- **Default Security Groups**: {{ values.createDefaultSecurityGroups and '✅ Enabled' or '❌ Disabled' }}
- **Security Group Templates**: {{ values.securityGroupTemplates | join(', ') if values.securityGroupTemplates else 'None selected' }}

### Network Access Control
- **Custom NACLs**: {{ values.useCustomNacls and '✅ Enabled' or '❌ Disabled' }}
- **VPC Peering**: {{ values.enableVpcPeering and '✅ Enabled' or '❌ Disabled' }}

### VPC Endpoints
- **VPC Endpoints**: {{ values.enableVpcEndpoints and '✅ Enabled' or '❌ Disabled' }}


## 📊 Monitoring and Logging

### VPC Flow Logs
- **Destination**: {{ values.vpcFlowLogsDestination }}
- **Traffic Type**: {{ values.vpcFlowLogsTrafficType }}

### CloudWatch Integration
- **CloudWatch Monitoring**: {{ values.enableCloudWatchMonitoring and '✅ Enabled' or '❌ Disabled' }}
- **CloudWatch Alerts**: {{ values.createCloudWatchAlerts and '✅ Enabled' or '❌ Disabled' }}

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **Access** to the target AWS account(s)

### Step 1: Configure Backend

Update the backend configuration in `main.tf`:

```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "networking/{{ values.projectName }}/terraform.tfstate"
    region = "{{ values.region }}"
  }
}
```

### Step 2: Review Configuration

Check the environment-specific `.tfvars` files:

- `{{ env }}.tfvars` - {{ env | title }} environment settings


### Step 3: Deploy Infrastructure

Deploy each environment using the appropriate `.tfvars` file:


**{{ env | title }} Environment:**
```bash
terraform init
terraform plan -var-file="{{ env }}.tfvars"
terraform apply -var-file="{{ env }}.tfvars"
```


### Alternative: Using Terraform Workspaces

You can also use Terraform workspaces for environment separation:


**{{ env | title }} Workspace:**
```bash
terraform workspace new {{ env }}
terraform plan -var-file="{{ env }}.tfvars"
terraform apply -var-file="{{ env }}.tfvars"
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
| `public_subnet_count` | Number of public subnets | `{{ values.publicSubnetCount }}` |
| `private_subnet_count` | Number of private subnets | `{{ values.privateSubnetCount }}` |
| `database_subnet_count` | Number of database subnets | `{{ values.databaseSubnetCount }}` |

### Advanced Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `nat_gateway_strategy` | NAT Gateway deployment | `{{ values.natGatewayStrategy }}` |
| `enable_vpc_endpoints` | Enable VPC endpoints | `{{ values.enableVpcEndpoints }}` |
| `enable_vpc_flow_logs` | Enable VPC Flow Logs | Varies by environment |
| `subnet_sizing_strategy` | Subnet CIDR allocation | `{{ values.subnetSizingStrategy }}` |

## 💰 Cost Estimation

### Monthly Cost Breakdown


| Component | Quantity | Estimated Cost (USD/month) |
|-----------|----------|---------------------------|
| NAT Gateways | Varies by strategy and AZ count | ~$45/gateway/month |


| VPC Flow Logs | Variable (traffic-based) | ~$10-50/month |

> **Note**: Costs are estimates and may vary based on actual usage, data transfer, and AWS pricing changes.

## 🔧 Usage Examples


### Deploy {{ env | title }} Environment
```bash
terraform init
terraform plan -var-file="{{ env }}.tfvars"
terraform apply -var-file="{{ env }}.tfvars"
```


### Destroy Environment
```bash
terraform destroy -var-file="<environment>.tfvars"
```

### Switch Between Environments
```bash
# View current resources
terraform show

# Plan changes for different environment
terraform plan -var-file="<environment>.tfvars"

# Apply changes
terraform apply -var-file="<environment>.tfvars"
```

## 🔒 Security Considerations

### Network Security
- Private subnets have no direct internet access

- NAT Gateways provide controlled outbound access

- Security groups and NACLs provide layered security


### Access Control
- IAM roles and policies control resource access
- Resource-based policies for fine-grained control
- Cross-account access configured where specified

### Monitoring

- CloudWatch metrics available for all network components
- Consider enabling AWS Config for compliance monitoring

## 🔧 Customization

### Adding New Environments

1. Create a new `.tfvars` file (e.g., `staging.tfvars`)
2. Copy configuration from an existing environment file
3. Update the `environment` variable and other settings
4. Deploy using `terraform apply -var-file="staging.tfvars"`

### Modifying Network Architecture

To change the network configuration:
1. Update variables in the appropriate `.tfvars` file
2. Run `terraform plan -var-file="<environment>.tfvars"` to review changes
3. Apply changes with `terraform apply -var-file="<environment>.tfvars"`

### Adding VPC Endpoints

Set `enable_vpc_endpoints = true` and specify services in `vpc_endpoint_services`:
```hcl
enable_vpc_endpoints = true
vpc_endpoint_services = ["s3", "ecr-api", "ecr-dkr", "ssm"]
```

### Custom Security Groups

Add custom security group templates by updating `security_group_templates`:
```hcl
security_group_templates = ["web-tier", "app-tier", "db-tier", "bastion"]
```

## 📊 Outputs

After deployment, Terraform will output important resource information:

- VPC ID and CIDR block
- Subnet IDs for each tier and availability zone
- Route table IDs
- NAT Gateway IPs (if enabled)
- Security Group IDs
- VPC endpoint IDs (if enabled)
- Cost estimation summary
- Resource inventory

Use these outputs in other Terraform configurations or applications.

## 🆘 Troubleshooting

### Common Issues

1. **CIDR Overlap**: Ensure VPC CIDRs don't overlap between environments
2. **Subnet Exhaustion**: Verify subnet count doesn't exceed available IPs
3. **AZ Availability**: Check that requested AZs are available in the region
4. **Resource Limits**: Ensure AWS service limits aren't exceeded

### Validation Commands

```bash
# Validate Terraform configuration
terraform validate

# Check formatting
terraform fmt -check

# Plan with detailed output
terraform plan -var-file="<environment>.tfvars" -detailed-exitcode
```

### Debugging

Enable Terraform debugging:
```bash
export TF_LOG=DEBUG
terraform apply -var-file="<environment>.tfvars"
```

## 📚 Additional Resources

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Cost Calculator](https://calculator.aws/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Generated by**: Backstage Advanced AWS Networking Template  
**Creation Date**: {{ "now" | date("Y-m-d H:i:s") }}  
**Template Version**: Advanced v1.0

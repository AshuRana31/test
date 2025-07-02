# AWS Networking Infrastructure

This Terraform configuration creates a complete AWS networking infrastructure including VPC, subnets, Internet Gateway, NAT Gateway (optional), and VPC Flow Logs (optional).

## Infrastructure Components

- VPC with DNS support and DNS hostnames enabled
- Public and private subnets across multiple availability zones
- Internet Gateway for public internet access
- NAT Gateway for private subnet internet access (optional)
- Route tables for public and private subnets
- VPC Flow Logs with CloudWatch integration (optional)

## Prerequisites

- AWS credentials configured
- Terraform installed (version >= 0.12)
- Access to create VPC and related resources in your AWS account

## Usage

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review the planned changes:
   ```bash
   terraform plan
   ```

3. Apply the configuration:
   ```bash
   terraform apply
   ```

## Input Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| region | AWS region for deployment | string | ap-southeast-2 |
| project_name | Name of the project | string | - |
| client_name | Name of the client | string | - |
| environment | Environment (Development, UAT, Production) | string | - |
| vpc_naming_convention | Naming convention for VPC resources | string | - |
| vpc_cidr | CIDR block for VPC | string | - |
| create_public_subnets | Whether to create public subnets | bool | true |
| create_private_subnets | Whether to create private subnets | bool | true |
| create_internet_gateway | Whether to create an Internet Gateway | bool | true |
| create_nat_gateway | Whether to create NAT Gateways | bool | false |
| enable_vpc_flow_logs | Whether to enable VPC Flow Logs | bool | false |
| availability_zones | List of availability zones to use | list(string) | ["ap-southeast-2a", "ap-southeast-2b"] |
| subnets_per_type | Number of subnets per type | number | 2 |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the created VPC |
| vpc_cidr | CIDR block of the created VPC |
| public_subnet_ids | IDs of the created public subnets |
| private_subnet_ids | IDs of the created private subnets |
| public_subnet_cidrs | CIDR blocks of the created public subnets |
| private_subnet_cidrs | CIDR blocks of the created private subnets |
| internet_gateway_id | ID of the created Internet Gateway |
| nat_gateway_id | ID of the created NAT Gateway |
| public_route_table_id | ID of the public route table |
| private_route_table_id | ID of the private route table |
| vpc_flow_log_group | Name of the CloudWatch Log Group for VPC Flow Logs |

## Resource Naming

Resources are named using the following convention:
- VPC: `${client_name}-${environment}-vpc`
- Subnets: `${vpc_name}-{public/private}-${az}`
- Internet Gateway: `${vpc_name}-igw`
- NAT Gateway: `${vpc_name}-nat`
- Route Tables: `${vpc_name}-{public/private}-rt`
- Flow Logs: `${vpc_name}-flow-logs`

## Security Considerations

- Public subnets have direct internet access through the Internet Gateway
- Private subnets can access the internet through NAT Gateway (if enabled)
- VPC Flow Logs can be enabled for network traffic monitoring
- All resources are tagged for better resource management

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

**Note:** This will permanently delete all created resources. Make sure this is what you want to do in the target environment.
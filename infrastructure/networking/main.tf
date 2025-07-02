# AWS Provider configuration
provider "aws" {
  region = var.region
}

# Data sources for AZ lookup
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # VPC naming
  vpc_name = replace(var.vpc_naming_convention, {
    client = var.client_name
    env    = var.environment
  })

  # Calculate subnet CIDRs
  public_subnet_cidrs  = var.create_public_subnets ? cidrsubnets(var.vpc_cidr, 2, 2) : []
  private_subnet_cidrs = var.create_private_subnets ? cidrsubnets(var.vpc_cidr, 2, 2) : []

  # Common tags
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Client      = var.client_name
    ManagedBy   = "terraform"
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.common_tags,
    {
      Name = local.vpc_name
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  count = var.create_internet_gateway ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-igw"
    }
  )
}

# Public Subnets
resource "aws_subnet" "public" {
  count             = var.create_public_subnets ? length(local.public_subnet_cidrs) : 0
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-public-${data.aws_availability_zones.available.names[count.index]}"
      Type = "public"
    }
  )
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = var.create_private_subnets ? length(local.private_subnet_cidrs) : 0
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-private-${data.aws_availability_zones.available.names[count.index]}"
      Type = "private"
    }
  )
}

# Public Route Table
resource "aws_route_table" "public" {
  count  = var.create_public_subnets ? 1 : 0
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-public-rt"
    }
  )
}

# Public Route Table Association
resource "aws_route_table_association" "public" {
  count          = var.create_public_subnets ? length(local.public_subnet_cidrs) : 0
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Private Route Table
resource "aws_route_table" "private" {
  count  = var.create_private_subnets ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-private-rt"
    }
  )
}

# Private Route Table Association
resource "aws_route_table_association" "private" {
  count          = var.create_private_subnets ? length(local.private_subnet_cidrs) : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

# NAT Gateway (Optional)
resource "aws_eip" "nat" {
  count = var.create_nat_gateway ? 1 : 0
  vpc   = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-nat-eip"
    }
  )
}

resource "aws_nat_gateway" "main" {
  count         = var.create_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-nat"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# VPC Flow Logs (Optional)
resource "aws_flow_log" "main" {
  count                = var.enable_vpc_flow_logs ? 1 : 0
  iam_role_arn        = aws_iam_role.flow_logs[0].arn
  log_destination     = aws_cloudwatch_log_group.flow_logs[0].arn
  traffic_type        = "ALL"
  vpc_id              = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-flow-logs"
    }
  )
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  count             = var.enable_vpc_flow_logs ? 1 : 0
  name              = "/aws/vpc-flow-logs/${local.vpc_name}"
  retention_in_days = 30

  tags = local.common_tags
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  name  = "${local.vpc_name}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  name  = "${local.vpc_name}-flow-logs-policy"
  role  = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}
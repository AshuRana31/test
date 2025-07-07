terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }

  backend "s3" {
    bucket         = "terraform-state-ashurana31-test-1751878282"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks-ashurana31-test"
    encrypt        = true
    role_arn       = "arn:aws:iam::038751964618:role/GitHubActionsRole"
  }

}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Environment = "infrastructure"
      Project     = "backstage-template"
    }
  }
}

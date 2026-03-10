terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    key            = "remediation-infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "jtb75-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      ManagedBy = "terraform"
      Project   = "gp-policies-remediation"
    }
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
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

provider "kubernetes" {
  host                   = aws_eks_cluster.remediation.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.remediation.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.remediation.name]
  }
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.remediation.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.remediation.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.remediation.name]
    }
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.32.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.13"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.7"
    }
  }

  backend "s3" {
    bucket = "terraform-state-testting"
    key    = "terraform2.tfstate"
    region = "us-east-1"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.32.0"
    }
  }

  backend "s3" {
    bucket = "terraform-state-testting"
    key    = "terraform2.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  availability_zones = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  private_subnets = [
    for az in local.availability_zones :
    cidrsubnet(var.cidr_block, 8, index(local.availability_zones, az))
  ]

  public_subnets = [
    for az in local.availability_zones :
    cidrsubnet(var.cidr_block, 8, index(local.availability_zones, az) + 100)
  ]
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# data "aws_ami" "eks_ami" {
#   filter {
#     name = "name"

#   }
#   owners      = ["amazon"]
#   most_recent = true
# }

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "EKS VPC"
  cidr = var.cidr_block

  azs             = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  enable_nat_gateway = true
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-allow"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_eks_cluster" "main" {
  name     = "Hello_World_Cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = module.vpc.private_subnets
  }
}

resource "aws_iam_role" "node_group_role" {
  name = "eks-node-group-allow"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group_role.name
}

resource "aws_eks_node_group" "main" {
  cluster_name  = aws_eks_cluster.main.name
  subnet_ids    = module.vpc.private_subnets
  node_role_arn = aws_iam_role.node_group_role.arn
  scaling_config {
    min_size     = var.cluster_min_size
    desired_size = var.cluster_desired_size
    max_size     = var.cluster_max_size
  }
}


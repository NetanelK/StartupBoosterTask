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

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "EKS VPC"
  cidr = var.cidr_block

  azs             = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

  enable_nat_gateway = true
}

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = module.vpc.private_subnets
  }
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


locals {
  ecr_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

data "aws_caller_identity" "current" {}
data "aws_ecr_authorization_token" "auth_token" {}
data "aws_eks_cluster_auth" "default" {
  name = module.eks.cluster_name
}

module "eks" {
  source = "./EKS"

  az_count             = var.az_count
  cidr_block           = var.cidr_block
  cluster_desired_size = var.cluster_desired_size
  cluster_max_size     = var.cluster_max_size
  cluster_min_size     = var.cluster_min_size
  cluster_name         = var.cluster_name
}

module "k8s" {
  source = "./K8s"

  oidc         = module.eks.oidc
  cluster_name = module.eks.cluster_name
  dockerconfigjson = jsonencode({
    "auths" = {
      "${local.ecr_registry}" = {
        "username" = "AWS"
        "password" = data.aws_ecr_authorization_token.auth_token.password
        "auth"     = data.aws_ecr_authorization_token.auth_token.authorization_token
      }
    }
  })

  depends_on = [
    module.eks
  ]
}

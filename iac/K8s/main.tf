resource "aws_iam_role" "lb_service_account_role" {
  name = "AmazonEKSLoadBalancerControllerRole"

  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "${var.oidc.arn}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "${var.oidc.url}:aud": "sts.amazonaws.com",
                    "${var.oidc.url}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_iam_policy" "AWSLoadBalancerControllerIAMPolicy" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = file("${path.module}/policy.json")
}

resource "aws_iam_role_policy_attachment" "AmazonEKSLoadBalancerControllerPolicy" {
  policy_arn = aws_iam_policy.AWSLoadBalancerControllerIAMPolicy.arn
  role       = aws_iam_role.lb_service_account_role.name

  depends_on = [
    aws_iam_policy.AWSLoadBalancerControllerIAMPolicy,
    aws_iam_role.lb_service_account_role
  ]
}

resource "kubernetes_secret" "regcred" {
  type = "kubernetes.io/dockerconfigjson"

  metadata {
    name = "regcred"
  }

  data = {
    ".dockerconfigjson" = var.dockerconfigjson
  }
}

resource "kubernetes_service_account" "lb_service_account" {
  metadata {
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
    }

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.lb_service_account_role.arn
    }

    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
  }
}

resource "helm_release" "lb_controller" {
  name       = "aws-load-balancer-controller"
  chart      = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }
  set {
    name  = "serviceAccount.create"
    value = false
  }
  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.lb_service_account.metadata.0.name
  }
}

output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "ca" {
  value = aws_eks_cluster.main.certificate_authority
}

output "oidc" {
  value = {
    arn = aws_iam_openid_connect_provider.oidc.arn
    url = replace(aws_iam_openid_connect_provider.oidc.url, "https://", "")
  }
}

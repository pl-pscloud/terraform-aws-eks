
output "pscloud_eks_cluster_endpoint" {
  value = aws_eks_cluster.pscloud-eks-cluster.endpoint
}

output "pscloud_eks_cluster_kubeconfig_ca_data" {
  value = aws_eks_cluster.pscloud-eks-cluster.certificate_authority.0.data
}
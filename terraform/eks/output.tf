# Output the EKS cluster API endpoint URL after creation
# This is useful for configuring kubectl and other tools to connect to the cluster
output "endpoint" {
  value = aws_eks_cluster.eks.endpoint
}
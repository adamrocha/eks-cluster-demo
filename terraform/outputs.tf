output "cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = aws_eks_cluster.eks.endpoint
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.eks.name
}

output "cluster_ca" {
  description = "Base64 encoded CA certificate for the EKS cluster"
  value       = aws_eks_cluster.eks.certificate_authority[0].data
  sensitive   = true
}

output "node_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = aws_iam_role.eks_nodes.arn
}

output "hello_world_service_endpoint" {
  description = "External endpoint of the hello-world LoadBalancer service"
  value       = "http://${kubernetes_service.hello_world_service.status[0].load_balancer[0].ingress[0].hostname}"
}


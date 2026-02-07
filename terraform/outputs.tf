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

# output "hello_world_service_endpoint" {
#   description = "External endpoint of the hello-world LoadBalancer service"
#   value       = "http://${kubernetes_service.hello_world_service.status[0].load_balancer[0].ingress[0].hostname}"
# }

# output "image_digest" {
#   value = data.external.image_digest.result["digest"]
# }

output "image_digests" {
  description = "ECR Image Digest"
  value       = data.aws_ecr_image.image.image_digest
}

# output "image_state" {
#   description = "ECR Image State"
#   value       = data.external.image_exists.result.exists
# }

# data "kubernetes_service" "grafana" {
#   metadata {
#     name      = "prometheus-grafana"
#     namespace = var.monitoring_ns
#   }
# }
# output "grafana_service_endpoint" {
#   description = "External endpoint of the Grafana LoadBalancer service"
#   value       = "http://${data.kubernetes_service.grafana.status[0].load_balancer[0].ingress[0].hostname}"
# }

# data "kubernetes_service" "prometheus" {
#   metadata {
#     name      = "prometheus-kube-prometheus-prometheus"
#     namespace = var.monitoring_ns
#   }
# }
# output "prometheus_service_endpoint" {
#   description = "External endpoint of the Prometheus LoadBalancer service"
#   value       = "http://${data.kubernetes_service.prometheus.status[0].load_balancer[0].ingress[0].hostname}:9090"
# }

# output "ecr_image" {
#   description = "Docker image to be used in the deployment"
#   value       = kubernetes_deployment.hello_world.spec[0].template[0].spec[0].container[0].image
# }
resource "helm_release" "prometheus" {
  depends_on = [
    aws_eks_node_group.node_group,
    aws_internet_gateway.eks,
    aws_nat_gateway.nat,
    aws_route_table.private,
    aws_route_table.public,
    aws_subnet.private,
    aws_subnet.public,
    aws_vpc.eks
  ]
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = var.monitoring_ns
  create_namespace = true
  timeout          = 600
  skip_crds        = false
  wait             = true
  version          = "76.4.0"
}
#   set {
#     name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
#     value = true
#   }
#   set {
#     name  = "prometheus.prometheusSpec.serviceMonitorSelector"
#     value = "{}"
#   }
#   set {
#     name  = "grafana.enabled"
#     value = true
#   }
#   set {
#     name  = "grafana.service.type"
#     value = "ClusterIP"
#   }
#   set {
#     name  = "grafana.service.port"
#     value = "80"
#   }
#   set {
#     name  = "prometheus.service.type"
#     value = "LoadBalancer"
#   }
#   set {
#     name  = "prometheus.service.loadBalancerType"
#     value = "nlb"
#   }
#   set {
#     name  = "grafana.service.type"
#     value = "LoadBalancer"
#   }
#   set {
#     name  = "grafana.service.loadBalancerType"
#     value = "nlb"
#   }
#   set {
#     name  = "fullnameOverride"
#     value = "prometheus"
#   }
#   set {
#     name  = "global.serviceAnnotations.service.beta.kubernetes.io/aws-load-balancer-connection-draining-enabled"
#     value = "false"
#   }
#   # Prometheus Service Finalizer Off
#   set {
#     name  = "prometheus.service.annotations.service\\.kubernetes\\.io/load-balancer-cleanup"
#     value = "\"true\""
#   }
#   # Grafana Service Finalizer Off
#   set {
#     name  = "grafana.service.annotations.service\\.kubernetes\\.io/load-balancer-cleanup"
#     value = "\"true\""
#   }
# }
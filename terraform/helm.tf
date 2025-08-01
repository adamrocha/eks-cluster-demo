# resource "helm_release" "cloudwatch_exporter" {
#   depends_on       = [aws_eks_node_group.node_group]
#   name             = "prometheus-cloudwatch-exporter"
#   repository       = "https://prometheus-community.github.io/helm-charts"
#   chart            = "prometheus-cloudwatch-exporter"
#   namespace        = "monitoring"
#   create_namespace = true
#   timeout          = 600

#   set {
#     name  = "service.type"
#     value = "ClusterIP"
#   }

#   set {
#     name  = "aws.region"
#     value = var.region
#   }
# }

# resource "helm_release" "kube_state_metrics" {
#   depends_on       = [aws_eks_node_group.node_group]
#   name             = "kube-state-metrics"
#   repository       = "https://prometheus-community.github.io/helm-charts"
#   chart            = "kube-state-metrics"
#   namespace        = "monitoring"
#   create_namespace = true
#   timeout          = 600

#   set {
#     name  = "service.type"
#     value = "LoadBalancer"
#   }
# }

resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = var.monitoring_ns
  create_namespace = true
  timeout          = 600
  wait             = true

  set {
    name  = "prometheus.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "prometheus.service.loadBalancerClass"
    value = "service.k8s.aws/nlb"
  }

  set {
    name  = "grafana.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "grafana.service.loadBalancerClass"
    value = "service.k8s.aws/nlb"
  }

  set {
    name  = "prometheus.service.externalTrafficPolicy"
    value = "Local"
  }

  set {
    name  = "grafana.service.externalTrafficPolicy"
    value = "Local"
  }
}

#   set {
#     name  = "prometheus.prometheusSpec.serviceMonitorSelector.matchLabels.k8s-app"
#     value = "kube-state-metrics"
#   }
#   set {
#     name  = "prometheus.prometheusSpec.serviceMonitorSelector.matchLabels.release"
#     value = "kube-state-metrics"
#   }
#   set {
#     name  = "prometheus.prometheusSpec.serviceMonitorSelector.matchLabels.app"
#     value = "kube-state-metrics"
#   }
#   set {
#     name  = "prometheus.prometheusSpec.serviceMonitorSelector.matchLabels.name"
#     value = "kube-state-metrics"
#   }
#   set {
#     name  = "prometheus.prometheusSpec.serviceMonitorSelector.matchLabels.k8s-app"
#     value = "prometheus-cloudwatch-exporter"
#   }
# }
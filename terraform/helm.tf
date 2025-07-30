resource "helm_release" "cloudwatch_exporter" {
    depends_on       = [aws_eks_cluster.eks]
    name             = "prometheus-cloudwatch-exporter"
    repository       = "https://prometheus-community.github.io/helm-charts"
    chart            = "prometheus-cloudwatch-exporter"
    namespace        = "monitoring"
    create_namespace = true
    timeout          = 600

    set {
        name  = "service.type"
        value = "ClusterIP"
    }

    set {
        name  = "aws.region"
        value = var.region
    }
}

resource "helm_release" "kube_state_metrics" {
  depends_on       = [aws_eks_cluster.eks]
  name             = "kube-state-metrics"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-state-metrics"
  namespace        = "monitoring"
  create_namespace = true
  timeout          = 600  

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }
}

resource "helm_release" "prometheus" {
  depends_on       = [aws_eks_cluster.eks]
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  timeout          = 600

  set {
    name  = "prometheus.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "grafana.service.type"
    value = "LoadBalancer"
  }
}
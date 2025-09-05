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
  version          = "76.4.0"
  namespace        = var.monitoring_ns
  create_namespace = true
  timeout          = 600
  skip_crds        = false
  wait             = true
}

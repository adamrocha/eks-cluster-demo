# resource "helm_release" "prometheus" {
#   name             = "prometheus"
#   repository       = "https://prometheus-community.github.io/helm-charts"
#   chart            = "prometheus"
#   namespace        = "monitoring"
#   create_namespace = true

#   set {
#     name  = "server.service.type"
#     value = "LoadBalancer"
#   }
# }

# resource "helm_release" "grafana" {
#   name             = "grafana"
#   repository       = "https://grafana.github.io/helm-charts"
#   chart            = "grafana"
#   namespace        = "monitoring"
#   create_namespace = true

#   set {
#     name  = "service.type"
#     value = "LoadBalancer"
#   }

#   set {
#     name  = "adminPassword"
#     value = "admin123"
#   }
# }

# resource "helm_release" "jenkins" {
#   name             = "jenkins"
#   repository       = "https://charts.jenkins.io"
#   chart            = "jenkins"
#   namespace        = "jenkins"
#   create_namespace = true

#   set {
#     name  = "controller.serviceType"
#     value = "LoadBalancer"
#   }

#   set {
#     name  = "controller.adminPassword"
#     value = "jenkins123"
#   }
# }

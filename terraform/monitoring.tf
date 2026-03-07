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
  version          = "81.5.0"
  namespace        = var.monitoring_ns
  create_namespace = true
  timeout          = 1800
  skip_crds        = false
  wait             = true
  wait_for_jobs    = false
  replace          = false

  values = [
    yamlencode({
      # Reduce resource requirements
      prometheus = {
        prometheusSpec = {
          replicas = 1
          resources = {
            requests = {
              cpu    = "200m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "2Gi"
            }
          }
          # Reduce retention to save resources
          retention = "7d"
          # Disable persistent storage to avoid PVC issues
          storageSpec = {}
        }
      }
      # Reduce Grafana resources
      grafana = {
        replicas = 1
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
        # Ensure sidecar containers also have resource requests so HPA CPU metrics are computable.
        sidecar = {
          resources = {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
        autoscaling = {
          enabled      = true
          minReplicas  = 1
          maxReplicas  = 3
          targetCPU    = 80
          targetMemory = 80
        }
        # Disable persistence to save resources
        persistence = {
          enabled = false
        }
      }
      # Disable Alertmanager to save pod slots
      alertmanager = {
        enabled = false
      }
      # Disable admission webhooks that can cause timeouts
      prometheusOperator = {
        admissionWebhooks = {
          enabled = false
          # Prevent cert-manager or job from running
          patch = {
            enabled = false
          }
        }
        # Remove TLS secret volume mounts since webhooks are disabled
        tls = {
          enabled = false
        }
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }
      # Keep kube-state-metrics but disable node-exporter (single node cluster)
      kubeStateMetrics = {
        enabled = true
        autoscaling = {
          enabled                           = true
          minReplicas                       = 1
          maxReplicas                       = 3
          targetCPUUtilizationPercentage    = 80
          targetMemoryUtilizationPercentage = 80
        }
      }
      nodeExporter = {
        enabled = false
      }
    })
  ]
}
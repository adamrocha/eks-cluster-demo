resource "kubernetes_namespace" "hello_world_ns" {
  # depends_on = [
  #   aws_eks_node_group.node_group,
  #   aws_eks_cluster.eks
  # ]

  metadata {
    name = "hello-world-ns"
    labels = {
      name = "hello-world-ns"
    }
  }
}

resource "kubernetes_service" "hello_world" {
  depends_on = [kubernetes_namespace.hello_world_ns]

  metadata {
    name      = "hello-world-service"
    namespace = kubernetes_namespace.hello_world_ns.metadata[0].name
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
    }
  }

  spec {
    selector = {
      app = "hello-world"
    }

    type = "LoadBalancer"

    port {
      name        = "http"
      protocol    = "TCP"
      port        = 80
      target_port = 5678
    }
  }
}

resource "kubernetes_deployment" "hello_world" {
  depends_on = [kubernetes_namespace.hello_world_ns]

  metadata {
    name      = "hello-world"
    namespace = kubernetes_namespace.hello_world_ns.metadata[0].name
    labels = {
      app = "hello-world"
    }
    annotations = {
      "deployment.kubernetes.io/revision" = "1"
      "description"                       = "Hello World Deployment"
    }
  }

  spec {
    replicas                  = 2
    revision_history_limit    = 10
    min_ready_seconds         = 5
    progress_deadline_seconds = 300

    selector {
      match_labels = {
        app = "hello-world"
      }
    }

    template {
      metadata {
        labels = {
          app = "hello-world"
        }
      }

      spec {
        security_context {
          run_as_non_root = true
          run_as_user     = 1000
          fs_group        = 2000
        }
        container {
          name              = "hello-world"
          image_pull_policy = "Always"
          image             = "hashicorp/http-echo:0.2.3"
          args              = ["-text=Hello, world!"]
          port {
            container_port = 5678
          }

          resources {
            limits = {
              cpu    = "250m"
              memory = "128Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "64Mi"
            }
          }
          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            capabilities {
              drop = ["ALL"]
            }
          }
          liveness_probe {
            http_get {
              path = "/"
              port = 5678
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }
          readiness_probe {
            http_get {
              path = "/"
              port = 5678
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }
}

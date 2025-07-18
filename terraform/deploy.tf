resource "kubernetes_namespace" "hello_world_ns" {
  depends_on = [
    aws_eks_node_group.node_group
  ]

  metadata {
    name = "hello-world-ns"
    labels = {
      name = "hello-world-ns"
    }
  }

  lifecycle {
    prevent_destroy = false
    # create_before_destroy = true # ensures Terraform can re-create a resource before deletion
  }
}

resource "kubernetes_service" "hello_world_service" {
  depends_on = []

  metadata {
    name      = var.service
    namespace = kubernetes_namespace.hello_world_ns.metadata[0].name
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
    }
  }

  spec {
    selector = {
      app = var.deployment
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
  # checkov:skip=CKV_K8S_43: development image, not production

  metadata {
    name      = var.deployment
    namespace = kubernetes_namespace.hello_world_ns.metadata[0].name
    labels = {
      app = var.deployment
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
        app = var.deployment
      }
    }

    template {
      metadata {
        labels = {
          app = var.deployment
        }
      }

      spec {
        security_context {
          run_as_non_root = true
          run_as_user     = 1000
          fs_group        = 2000
        }
        container {
          name              = var.deployment
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

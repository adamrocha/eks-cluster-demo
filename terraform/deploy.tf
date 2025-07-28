resource "kubernetes_namespace" "hello_world_ns" {

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
      target_port = 8080
    }
  }
}

resource "kubernetes_deployment" "hello_world" {

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
    replicas                  = 3
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
        automount_service_account_token = false

        security_context {
          run_as_non_root = true
          run_as_user     = 10001
        }

        volume {
          name = "nginx-cache"
          empty_dir {}
        }

        volume {
          name = "nginx-run"
          empty_dir {}
        }

        container {
          name              = var.deployment
          image_pull_policy = "Always"
          image             = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.repo_name}:${var.image_tag}@${var.image_digest}"
          # image             = "adamrocha/hello-world-demo:1.2.0"
          # image             = "hashicorp/http-echo:1.0"
          # args              = ["-text=👋 Hello from Kubernetes!"]
          port {
            container_port = 80
            protocol       = "TCP"
          }

          volume_mount {
            name       = "nginx-cache"
            mount_path = "/var/cache/nginx"
          }

          volume_mount {
            name       = "nginx-run"
            mount_path = "/var/run"
          }

          resources {
            limits = {
              cpu    = "100m"
              memory = "64Mi"
            }
            requests = {
              cpu    = "50m"
              memory = "32Mi"
            }
          }
          security_context {
            run_as_user                = 10001
            run_as_non_root            = true
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            seccomp_profile {
              type = "RuntimeDefault"
            }
            capabilities {
              drop = ["ALL"]
            }
          }
          liveness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }
          readiness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }
}

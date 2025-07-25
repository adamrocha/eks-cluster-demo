resource "null_resource" "configure_kubectl" {
  depends_on = [aws_eks_cluster.eks]

  triggers = {
    cluster_name = aws_eks_cluster.eks.id
    # endpoint     = aws_eks_cluster.eks.endpoint
    # master_auth  = sha1(jsonencode(aws_eks_cluster.eks.identity[0].oidc[0].issuer))
  }

  provisioner "local-exec" {
    command     = <<EOF
    aws eks update-kubeconfig \
    --region=${var.region} \
    --name=${var.cluster_name}
    EOF
    interpreter = ["bash", "-c"]
  }
}

resource "null_resource" "image_build" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command     = "../scripts/image.sh"
    interpreter = ["bash", "-c"]
  }
}

# # Null resource to force delete all pods in the namespace
# resource "null_resource" "force_delete_stuck_pods" {
#   depends_on = []

#   triggers = {
#     always    = timestamp()
#     namespace = var.deployment
#   }

#   provisioner "local-exec" {
#     when        = destroy
#     interpreter = ["bash", "-c"]
#     # This command will force delete all pods in the specified namespace
#     command = <<EOT
#       echo "Force-deleting all pods in namespace ${self.triggers.namespace}..."
#       kubectl get pods -n ${self.triggers.namespace} --no-headers \
#       | awk '{print \$1}' \
#       | xargs -r -I {} kubectl delete pod {} --force --grace-period=0 -n ${self.triggers.namespace}
#     EOT
#   }
#   lifecycle {
#     prevent_destroy = false
#   }
# }


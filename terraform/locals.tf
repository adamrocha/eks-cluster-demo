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

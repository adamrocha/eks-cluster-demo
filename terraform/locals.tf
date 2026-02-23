resource "terraform_data" "update_kubeconfig" {
  depends_on = [aws_eks_cluster.eks]

  triggers_replace = { cluster_name = aws_eks_cluster.eks.id }

  provisioner "local-exec" {
    command     = "aws eks update-kubeconfig --name ${var.cluster_name} --region ${var.region}"
    interpreter = ["bash", "-c"]
  }
}
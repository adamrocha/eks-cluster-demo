resource "null_resource" "update_kubeconfig" {
  depends_on = [aws_eks_cluster.eks]

  triggers = { cluster_name = aws_eks_cluster.eks.id }

  provisioner "local-exec" {
    command     = <<EOF
    aws eks update-kubeconfig \
    --region=${var.region} \
    --name=${var.cluster_name}
    EOF
    interpreter = ["bash", "-c"]
  }
}

data "external" "image_exists" {
  program = [
    "bash", "-c", <<EOT
      REGION="$REGION"
      REPO_NAME="$REPO_NAME"
      IMAGE_TAG="$IMAGE_TAG"

      if aws ecr describe-images \
          --region \"$REGION\" \
          --repository-name \"$REPO_NAME\" \
          --image-ids imageTag=\"$IMAGE_TAG\" \
          --query \"imageDetails[0].imageTags\" \
          --output text >/dev/null 2>&1; then
        echo '{"exists": "true"}'
      else
        echo '{"exists": "false"}'
      fi
    EOT
  ]
  query = {
    REGION    = var.region
    REPO_NAME = var.repo_name
    IMAGE_TAG = var.image_tag
  }
}

resource "null_resource" "image_build" {
  count = data.external.image_exists.result.exists == "false" ? 1 : 0

  provisioner "local-exec" {
    command     = "../scripts/docker-image.sh"
    interpreter = ["bash", "-c"]
  }
}


# resource "null_resource" "cleanup_lb" {
#   depends_on = [
#     helm_release.prometheus,
#     aws_eks_node_group.node_group,
#     aws_internet_gateway.eks,
#     aws_nat_gateway.nat,
#     aws_route_table.private,
#     aws_route_table.public,
#     aws_subnet.private,
#     aws_subnet.public,
#     aws_vpc.eks
#   ]
#   provisioner "local-exec" {
#     when        = destroy
#     command     = "../scripts/cleanup_lb.sh monitoring-ns"
#     interpreter = ["bash", "-c"]
#   }

#   triggers = {
#     always_run = timestamp()
#   }
# }

# resource "null_resource" "cleanup_sg" {
#   depends_on = []
#   provisioner "local-exec" {
#     when        = destroy
#     command     = "../scripts/cleanup_sg.sh"
#     interpreter = ["bash", "-c"]
#   }

#   triggers = {
#     always_run = timestamp()
#   }
# }

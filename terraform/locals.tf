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

# Ensure the ECR repository exists
resource "aws_ecr_repository" "repo" {
  name                 = var.repo_name
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  encryption_configuration {
    encryption_type = "KMS"
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Check if the image exists
data "external" "image_exists" {
  depends_on = [aws_ecr_repository.repo]
  program = [
    "bash", "-c", <<EOT
      REGION="${var.region}"
      REPO_NAME="${var.repo_name}"
      IMAGE_TAG="${var.image_tag}"

      if aws ecr describe-images \
          --region "$REGION" \
          --repository-name "$REPO_NAME" \
          --image-ids imageTag="$IMAGE_TAG" \
          --query "imageDetails[0].imageTags" \
          --output text >/dev/null 2>&1; then
        echo '{"exists": "true"}'
      else
        echo '{"exists": "false"}'
      fi
    EOT
  ]
}

# Build image only if it doesn't exist
resource "null_resource" "image_build" {
  depends_on = [
    aws_ecr_repository.repo,
    data.external.image_exists
  ]
  # count = data.external.image_exists.result.exists == "false" ? 1 : 0

  provisioner "local-exec" {
    command     = <<EOT
      if [ "${data.external.image_exists.result.exists}" = "false" ]; then
        ../scripts/docker-image.sh
      else
        echo "Image already exists, skipping build."
      fi
    EOT
    interpreter = ["bash", "-c"]
  }
}

# Get the image digest
data "external" "image_digest" {
  depends_on = [null_resource.image_build]
  program = [
    "bash", "-c", <<EOT
      REGION="${var.region}"
      REPO_NAME="${var.repo_name}"
      IMAGE_TAG="${var.image_tag}"

      DIGEST=$(aws ecr describe-images \
        --region "$REGION" \
        --repository-name "$REPO_NAME" \
        --image-ids imageTag="$IMAGE_TAG" \
        --query "imageDetails[0].imageDigest" \
        --output text)

      echo "{\"digest\": \"$DIGEST\"}"
    EOT
  ]
}

# Lookup the image safely
# data "aws_ecr_image" "image" {
#   depends_on = [
#     aws_eks_cluster.eks,
#     aws_ecr_repository.repo,
#     data.external.image_exists
#   ]
#   region          = var.region
#   repository_name = aws_ecr_repository.repo.name
#   image_tag       = var.image_tag
# }

# Use try() to avoid errors when the image doesn't exist
# locals {
#   image_digest = try(data.aws_ecr_image.image.image_digest, "")
# }

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

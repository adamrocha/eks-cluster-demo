resource "terraform_data" "update_kubeconfig" {
  depends_on = [aws_eks_cluster.eks]

  triggers_replace = { cluster_name = aws_eks_cluster.eks.id }

  provisioner "local-exec" {
    command     = "aws eks update-kubeconfig --name ${var.cluster_name} --region ${var.region}"
    interpreter = ["bash", "-c"]
  }
}

data "aws_ecr_authorization_token" "token" {}

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

# resource "docker_image" "hello_world" {
#   name = "${aws_ecr_repository.repo.repository_url}:${var.image_tag}"

#   build {
#     context    = "../app"
#     dockerfile = "Dockerfile"
#     # platforms = var.platforms
#     platform = var.platform
#   }
# }

# resource "docker_registry_image" "hello_world" {
#   name = docker_image.hello_world.name
# }

# Multi-architecture build using docker buildx
resource "terraform_data" "docker_buildx" {
  depends_on = [aws_ecr_repository.repo]

  triggers_replace = {
    image_tag  = var.image_tag
    platforms  = join(",", var.platforms)
    dockerfile = filemd5("../app/Dockerfile")
  }

  provisioner "local-exec" {
    command     = <<-EOT
      set -e
      echo "🔨 Building multi-architecture image..."
      
      # Login to ECR
      aws ecr get-login-password --region ${var.region} | \
        docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com
      
      # Create buildx builder if not exists
      docker buildx create --use --name multiarch-builder 2>/dev/null || docker buildx use multiarch-builder
      
      # Build and push multi-arch image
      docker buildx build \
        --platform ${join(",", var.platforms)} \
        --tag ${aws_ecr_repository.repo.repository_url}:${var.image_tag} \
        --push \
        ../app/
      
      echo "✅ Multi-arch image pushed successfully"
    EOT
    interpreter = ["bash", "-c"]
  }
}

# Lookup the image safely
data "aws_ecr_image" "image" {
  depends_on = [
    aws_eks_cluster.eks,
    aws_ecr_repository.repo,
    terraform_data.docker_buildx
    # docker_image.hello_world,
    # docker_registry_image.hello_world
  ]
  region          = var.region
  repository_name = aws_ecr_repository.repo.name
  image_tag       = var.image_tag
}

# resource "null_resource" "update_kubeconfig" {
#   depends_on = [aws_eks_cluster.eks]

#   triggers = { cluster_name = aws_eks_cluster.eks.id }

#   provisioner "local-exec" {
#     command     = <<EOF
#     aws eks update-kubeconfig \
#     --region=${var.region} \
#     --name=${var.cluster_name}
#     EOF
#     interpreter = ["bash", "-c"]
#   }
# }

# # Check if the image exists
# data "external" "image_exists" {
#   depends_on = [aws_ecr_repository.repo]
#   program = [
#     "bash", "-c", <<EOT
#       REGION="${var.region}"
#       REPO_NAME="${var.repo_name}"
#       IMAGE_TAG="${var.image_tag}"

#       if aws ecr describe-images \
#           --region "$REGION" \
#           --repository-name "$REPO_NAME" \
#           --image-ids imageTag="$IMAGE_TAG" \
#           --query "imageDetails[0].imageTags" \
#           --output text >/dev/null 2>&1; then
#         echo '{"exists": "true"}'
#       else
#         echo '{"exists": "false"}'
#       fi
#     EOT
#   ]
# }

# # Get the image digest
# data "external" "image_digest" {
#   depends_on = [docker_image.hello_world]
#   program = [
#     "bash", "-c", <<EOT
#       REGION="${var.region}"
#       REPO_NAME="${var.repo_name}"
#       IMAGE_TAG="${var.image_tag}"

#       DIGEST=$(aws ecr describe-images \
#         --region "$REGION" \
#         --repository-name "$REPO_NAME" \
#         --image-ids imageTag="$IMAGE_TAG" \
#         --query "imageDetails[0].imageDigest" \
#         --output text)

#       echo "{\"digest\": \"$DIGEST\"}"
#     EOT
#   ]
# }

# # Build image only if it doesn't exist
# resource "null_resource" "image_build" {
#   depends_on = [
#     aws_ecr_repository.repo,
#     data.external.image_exists
#   ]
#   triggers = {
#     image_tag      = var.image_tag
#     aws_account_id = data.aws_caller_identity.current.account_id
#     region         = var.region
#     repo_name      = var.repo_name
#     platforms      = join(",", var.platforms)
#   }
#   provisioner "local-exec" {
#     environment = {
#       AWS_ACCOUNT_ID = data.aws_caller_identity.current.account_id
#       AWS_REGION     = var.region
#       REPO_NAME      = var.repo_name
#       IMAGE_TAG      = var.image_tag
#       PLATFORMS      = join(",", var.platforms)
#     }
#     command     = <<EOT
#       if [ "${data.external.image_exists.result.exists}" = "false"; then
#         ../scripts/docker-image.sh
#       else
#         echo "Image already exists, skipping build."
#       fi
#     EOT
#     interpreter = ["bash", "-c"]
#   }
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

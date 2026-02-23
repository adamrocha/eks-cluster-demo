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

# Multi-architecture build using docker buildx
resource "terraform_data" "docker_buildx" {
  depends_on = [aws_ecr_repository.repo]

  triggers_replace = {
    image_tag  = var.image_tag
    platforms  = join(",", var.platforms)
    dockerfile = filemd5("../app/Dockerfile")
    entrypoint = filemd5("../app/entrypoint.sh")
    index_html = filemd5("../app/index.html")
    nginx_conf = filemd5("../app/nginx.conf")
  }

  provisioner "local-exec" {
    command     = <<-EOT
      set -euo pipefail
      echo "🔨 Building multi-architecture image..."

      IMAGE_EXISTS="false"
      if aws ecr describe-images \
        --region "${var.region}" \
        --repository-name "${aws_ecr_repository.repo.name}" \
        --image-ids imageTag="${var.image_tag}" \
        --query "imageDetails[0].imageTags" \
        --output text >/dev/null 2>&1; then
        IMAGE_EXISTS="true"
      fi

      echo "ℹ️  ECR tag exists (${var.image_tag}): $${IMAGE_EXISTS}"

      # Skip build/push if immutable tag already exists
      if [ "$${IMAGE_EXISTS}" = "true" ]; then
        echo "ℹ️  Image ${aws_ecr_repository.repo.repository_url}:${var.image_tag} already exists. Skipping build and push."
        exit 0
      fi
      
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
# data "aws_ecr_image" "image" {
#   depends_on = [
#     aws_eks_cluster.eks,
#     aws_ecr_repository.repo,
#     terraform_data.docker_buildx
#     # docker_image.hello_world,
#     # docker_registry_image.hello_world
#   ]
#   region          = var.region
#   repository_name = aws_ecr_repository.repo.name
#   image_tag       = var.image_tag
# }

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

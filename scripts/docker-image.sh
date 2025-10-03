#!/usr/bin/env bash
# Build and push hello-world Docker image to AWS ECR
# Supports multi-platform builds, auto-creates repo, installs/updates docker-credential-ecr-login,
# and checks image existence using docker pull


set -euo pipefail

# ------------------------------------------------------------
# Config
# ------------------------------------------------------------
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="802645170184"
REPO_NAME="hello-world-demo"
IMAGE_TAG="${IMAGE_TAG:-1.2.5}"
PLATFORMS="linux/amd64,linux/arm64"

export PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

cd "$PROJECT_ROOT/kube/" || exit 1

# ------------------------------------------------------------
# Image path
# ------------------------------------------------------------
IMAGE_PATH="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}"

if ! command -v aws >/dev/null 2>&1; then
  echo "❌ AWS CLI not installed."
  exit 1
fi

# Verify AWS credentials
if ! aws sts get-caller-identity --region "$AWS_REGION" >/dev/null 2>&1; then
  echo "❌ AWS credentials not configured or expired."
  exit 1
fi

# ------------------------------------------------------------
# Ensure ECR repository exists
# ------------------------------------------------------------
if ! aws ecr describe-repositories \
    --region "$AWS_REGION" \
    --repository-names "$REPO_NAME" &>/dev/null; then
  echo "📦 Creating ECR repository: $REPO_NAME..."
  aws ecr create-repository \
    --region "$AWS_REGION" \
    --repository-name "$REPO_NAME" >/dev/null
else
  echo "✅ ECR repository $REPO_NAME already exists."
fi

# ------------------------------------------------------------
# Check if image tag exists in ECR using AWS CLI
# ------------------------------------------------------------
if aws ecr describe-images \
  --repository-name "$REPO_NAME" \
  --region "$AWS_REGION" \
  --image-ids imageTag="$IMAGE_TAG" \
  --query 'imageDetails[0].imageTags' \
  --output text 2>/dev/null | grep -qw "$IMAGE_TAG"; then
  echo "✅ Image $IMAGE_PATH already exists in ECR."
  exit 0
fi

# ------------------------------------------------------------
# Ensure AWS ECR credential helper
# ------------------------------------------------------------
# For instructions on installing and configuring the Docker ECR credential helper, see:
# https://github.com/awslabs/amazon-ecr-credential-helper or AWS ECR documentation.
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
echo "🔐 Logging Docker in to ECR: $ECR_REGISTRY"
if ! aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$ECR_REGISTRY"; then
  echo "❌ Docker login to ECR failed."
  exit 1
fi

# ------------------------------------------------------------
# Verify Docker + Buildx
# ------------------------------------------------------------
if ! command -v docker &> /dev/null; then
  echo "❌ Docker not installed."
  exit 1
fi
if ! docker buildx version &> /dev/null; then
  echo "❌ Docker Buildx not installed."
  exit 1
fi

# Ensure buildx builder exists
if ! docker buildx inspect mybuilder >/dev/null 2>&1; then
  docker buildx create --name mybuilder --driver docker-container --use
else
  docker buildx use mybuilder
fi

# ------------------------------------------------------------
# Build + Push
# ------------------------------------------------------------
if ! docker buildx build \
  --platform "$PLATFORMS" \
  -t "$IMAGE_PATH" \
  --push .; then
  echo "❌ Docker build failed."
  exit 1
else
  echo "✅ Successfully built and pushed $IMAGE_PATH to ECR."
  exit 0
fi

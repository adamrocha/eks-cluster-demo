#!/usr/bin/env bash
# Build and push hello-world Docker image to AWS ECR
# Supports multi-platform builds, auto-creates repo, installs/updates docker-credential-ecr-login,
# and checks image existence using docker pull


set -euo pipefail

# ------------------------------------------------------------
# Config
# ------------------------------------------------------------
AWS_REGION="us-east-1"                 # AWS region
AWS_ACCOUNT_ID="802645170184"          # Replace with your AWS account ID
REPO="hello-world-demo"                # Flat ECR repository name (no nested paths)
IMAGE_TAG="${IMAGE_TAG:-1.2.2}"        # Default tag, can be overridden
PLATFORMS="linux/amd64,linux/arm64"

export PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$PROJECT_ROOT/kube/" || exit 1

OS_TYPE="$(uname -s)"

cd "$PROJECT_ROOT/kube/" || exit 1

# ------------------------------------------------------------
# Image path
# ------------------------------------------------------------
IMAGE_FULL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO}:${IMAGE_TAG}"


# ------------------------------------------------------------
# Check if image tag exists in ECR using AWS CLI (no Docker required)
# ------------------------------------------------------------
if aws ecr describe-images \
  --repository-name "$REPO" \
  --region "$AWS_REGION" \
  --image-ids imageTag="$IMAGE_TAG" \
  --query 'imageDetails[0].imageTags' \
  --output text 2>/dev/null | grep -qw "$IMAGE_TAG"; then
  echo "✅ Image $IMAGE_FULL already exists in ECR."
  exit 0
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
if ! docker buildx inspect multiarch >/dev/null 2>&1; then
  docker buildx create --name multiarch --use
else
  docker buildx use multiarch
fi

# ------------------------------------------------------------
# Ensure AWS ECR credential helper
# ------------------------------------------------------------
if ! command -v docker-credential-ecr-login >/dev/null 2>&1 && [[ "$OS_TYPE" == "Linux" ]]; then
    echo "🔧 Installing docker-credential-ecr-login..."
    sudo apt-get update -qq
    sudo apt-get install -y amazon-ecr-credential-helper
elif ! command -v docker-credential-osxkeychain >/dev/null 2>&1 && [[ "$OS_TYPE" == "Darwin" ]]; then
    echo "🔧 Installing docker-credential-helper for Mac..."
    brew install docker-credential-helper 
fi

# Configure Docker to use the helper for the ECR registry
DOCKER_CONFIG_DIR="${DOCKER_CONFIG:-$HOME/.docker}"
mkdir -p "$DOCKER_CONFIG_DIR"
cat > "$DOCKER_CONFIG_DIR/config.json" <<EOF
{
  "credHelpers": {
    "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com": "ecr-login"
  }
}
EOF

# ------------------------------------------------------------
# Ensure ECR repository exists
# ------------------------------------------------------------
if ! aws ecr describe-repositories \
    --region "$AWS_REGION" \
    --repository-names "$REPO" &>/dev/null; then
  echo "📦 Creating ECR repository: $REPO..."
  aws ecr create-repository \
    --region "$AWS_REGION" \
    --repository-name "$REPO" >/dev/null
else
  echo "✅ ECR repository $REPO exists."
fi

# ------------------------------------------------------------
# Build + Push
# ------------------------------------------------------------
if ! docker buildx build \
  --platform "$PLATFORMS" \
  -t "$IMAGE_FULL" \
  --push .; then
  echo "❌ Docker build failed."
  exit 1
else
  echo "✅ Successfully built and pushed $IMAGE_FULL."
  exit 0
fi

#!/bin/bash
# Script to update the Docker image in hello-world-deployment.yaml

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_FILE="$SCRIPT_DIR/../manifests/hello-world-deployment.yaml"
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-$(pass aws/dev/aws_account_id)}"
OSTYPE="$(uname -s)"


usage() {
    cat <<EOF
Usage: $0 <repository> <tag> [--no-digest]

Update the Docker image reference in hello-world-deployment.yaml

Arguments:
  repository    ECR repository name (e.g., hello-world-demo)
  tag           Image tag (e.g., 1.0.0)
  --no-digest   Skip fetching and adding image digest (optional)

Examples:
  # Update with digest (recommended)
  $0 hello-world-demo 1.0.0

  # Update without digest
  $0 hello-world-demo 1.0.0 --no-digest
EOF
    exit 1
}

# Parse arguments
if [ $# -lt 2 ]; then
    usage
fi

REPO_NAME="$1"
IMAGE_TAG="$2"
USE_DIGEST=true

if [ "${3:-}" = "--no-digest" ]; then
    USE_DIGEST=false
fi

# Construct base image URL
IMAGE_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}"

# Fetch digest if requested
if [ "$USE_DIGEST" = true ]; then
    echo "🔍 Fetching image digest from ECR..."
    
    # Get image digest
    DIGEST=$(aws ecr describe-images \
        --repository-name "$REPO_NAME" \
        --image-ids imageTag="$IMAGE_TAG" \
        --region "$AWS_REGION" \
        --query 'imageDetails[0].imageDigest' \
        --output text)
    
    if [ -z "$DIGEST" ] || [ "$DIGEST" = "None" ]; then
        echo "❌ Error: Could not find digest for image ${REPO_NAME}:${IMAGE_TAG}"
        echo "   Make sure the image exists in ECR and the tag is correct."
        exit 1
    fi
    
    FULL_IMAGE_URL="${IMAGE_URL}@${DIGEST}"
    echo "✅ Found digest: ${DIGEST}"
else
    FULL_IMAGE_URL="$IMAGE_URL"
    echo "⚠️  Skipping digest (not recommended for production)"
fi

# Check if manifest file exists
if [ ! -f "$MANIFEST_FILE" ]; then
    echo "❌ Error: Manifest file not found: $MANIFEST_FILE"
    exit 1
fi

# Update the manifest file
echo "📝 Updating manifest file..."

# Use sed to replace the image line
# This looks for a line with 'image:' followed by the ECR URL pattern
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS sed syntax
    sed -i '' "s|image: ${AWS_ACCOUNT_ID}\.dkr\.ecr\..*|image: ${FULL_IMAGE_URL}|" "$MANIFEST_FILE"
else
    # Linux sed syntax
    sed -i "s|image: ${AWS_ACCOUNT_ID}\.dkr\.ecr\..*|image: ${FULL_IMAGE_URL}|" "$MANIFEST_FILE"
fi

echo "✅ Updated image reference in $MANIFEST_FILE"
echo ""
echo "New image: $FULL_IMAGE_URL"
echo ""
echo "To apply the changes:"
echo "  kubectl apply -f $MANIFEST_FILE"
echo "  or"
echo "  make k8s-apply"

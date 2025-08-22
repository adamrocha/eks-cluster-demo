#!/bin/bash
# This script builds a Docker image, tags it for Amazon ECR, logs in to ECR,
# checks if the ECR repository exists, creates it if not, and pushes the image to ECR.

# --------- CONFIGURATION ---------
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="802645170184"
REPO_NAME="hello-world-demo"
IMAGE_TAG="1.2.2"
LOCAL_IMAGE_NAME="hello-world-demo"
PLATFORM_ARCH="linux/arm64"
# ---------------------------------

cd ../kube/ || exit 1

ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}"

echo "🔐 Authenticating Docker to Amazon ECR..."
aws ecr get-login-password \
  --region "${AWS_REGION}" \
  | docker login \
  --username AWS \
  --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "🔍 Checking if ECR repository '${REPO_NAME}' exists..."
if ! aws ecr describe-repositories \
  --repository-names "${REPO_NAME}" \
  --region "${AWS_REGION}" >/dev/null 2>&1; then
  echo "📁 Repository not found. Creating ECR repository: ${REPO_NAME}"
  aws ecr create-repository \
  --repository-name "${REPO_NAME}" \
  --region "${AWS_REGION}" >/dev/null
else
  echo "✅ Repository '${REPO_NAME}' already exists."
fi

echo "🔍 Checking if image '${IMAGE_TAG}' exists in '${REPO_NAME}'..."
IMAGE_EXISTS=$(aws ecr describe-images \
  --repository-name "${REPO_NAME}" \
  --region "${AWS_REGION}" \
  --query "imageDetails[?imageTags && contains(imageTags, \`${IMAGE_TAG}\`)]" \
  --output json)

if [[ "${IMAGE_EXISTS}" == "[]" ]]; then
  echo "🚫 Image with tag '${IMAGE_TAG}' not found. Building and pushing..."
  docker buildx build \
  --platform ${PLATFORM_ARCH} \
  -t ${LOCAL_IMAGE_NAME}:${IMAGE_TAG} .
  docker tag ${LOCAL_IMAGE_NAME}:${IMAGE_TAG} ${ECR_URI}
  docker push ${ECR_URI}
  echo "✅ Image pushed to: ${ECR_URI}"
else
  echo "✅ Image '${IMAGE_TAG}' already exists in '${REPO_NAME}'. No action needed."
fi
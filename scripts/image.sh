#!/bin/bash
# This script builds a Docker image, tags it for Amazon ECR, logs in to ECR,
# checks if the ECR repository exists, creates it if not, and pushes the image to ECR.

# --------- CONFIGURATION ---------
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="802645170184"
REPO_NAME="hello-world-demo"
IMAGE_TAG="1.2.0"
LOCAL_IMAGE_NAME="hello-world"
PLATFORM_ARCH="linux/arm64"
# ---------------------------------

cd ../kube/ || exit 1

ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}"

echo "🛠️ Building local image: ${LOCAL_IMAGE_NAME}:${IMAGE_TAG}"
docker build \
  --platform ${PLATFORM_ARCH} \
  --tag ${LOCAL_IMAGE_NAME}:${IMAGE_TAG} \
  --push .

echo "🔗 Tagging image for ECR: ${ECR_URI}"
docker tag ${LOCAL_IMAGE_NAME}:${IMAGE_TAG} ${ECR_URI}

echo "🔐 Logging in to Amazon ECR..."
aws ecr get-login-password \
  --region ${AWS_REGION} \
  | docker login \
  --username AWS \
  --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

echo "📦 Checking if ECR repo exists: ${REPO_NAME}"
if ! aws ecr describe-repositories \
  --repository-names "${REPO_NAME}" \
  --region ${AWS_REGION} >/dev/null 2>&1
then
  echo "📁 Repository not found. Creating ECR repository: ${REPO_NAME}"
  aws ecr create-repository \
    --repository-name "${REPO_NAME}" \
    --region ${AWS_REGION}
else
  echo "✅ Repository already exists."
fi

echo "📤 Pushing image to ECR: ${ECR_URI}"
docker push ${ECR_URI}

echo "✅ Done! Image pushed to ${ECR_URI}"

#!/usr/bin/env bash

export AWS_PAGER=""

set -euo pipefail

CLUSTER_NAME="eks-demo-cluster"
AWS_REGION="us-east-1"
AWS_PROFILE="prom_infradmin"

# 1. Create AWS CLI config with credential_process using pass
mkdir -p ~/.aws
cat > ~/.aws/config <<EOF
[default]
region = ${AWS_REGION}
output = json

[profile ${AWS_PROFILE}]
region = ${AWS_REGION}
output = json
credential_process = aws-pass-creds
EOF

echo "[INFO] AWS CLI config written with credential_process=aws-pass-creds for profile ${AWS_PROFILE}"

# 2. Verify AWS CLI authentication
echo "[INFO] Testing AWS CLI authentication via pass..."
aws sts get-caller-identity --profile "${AWS_PROFILE}"

# 3. Update kubeconfig for EKS cluster
echo "[INFO] Updating kubeconfig for EKS cluster ${CLUSTER_NAME} in region ${AWS_REGION} using profile ${AWS_PROFILE}..."
aws eks update-kubeconfig \
  --region "$AWS_REGION" \
  --name "$CLUSTER_NAME" \
  --profile "$AWS_PROFILE" \
  --alias "${CLUSTER_NAME}-${AWS_PROFILE}"

# 4. Configure kubectl to use this profile for EKS
echo "[INFO] Updating kubeconfig for cluster ${CLUSTER_NAME}..."
kubectl config set-credentials ${AWS_PROFILE} \
  --exec-command aws \
  --exec-api-version client.authentication.k8s.io/v1beta1 \
  --exec-arg eks \
  --exec-arg get-token \
  --exec-arg --cluster-name \
  --exec-arg ${CLUSTER_NAME} \
  --exec-arg --region \
  --exec-arg ${AWS_REGION} \
  --exec-arg --profile \
  --exec-arg ${AWS_PROFILE}

kubectl config set-context pass-context \
  --cluster="arn:aws:eks:${AWS_REGION}:$(aws sts get-caller-identity --query 'Account' --output text --profile ${AWS_PROFILE}):cluster/${CLUSTER_NAME}" \
  --user=${AWS_PROFILE}

kubectl config use-context pass-context

echo "[INFO] kubeconfig updated. You can now run:"
echo "       kubectl get nodes"
echo "without setting AWS_PROFILE"

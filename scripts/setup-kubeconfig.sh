#!/bin/bash
# This script sets up the kubeconfig for an EKS cluster.

REGION="us-east-1"
CLUSTER_NAME="eks-demo-cluster"
AWS_PROFILE="prom_infradmin"

aws eks update-kubeconfig \
  --region "$REGION" \
  --name "$CLUSTER_NAME" \
  --profile "$AWS_PROFILE" \
  --alias "${CLUSTER_NAME}-${AWS_PROFILE}"

echo "Done. Verifying auth..."
kubectl get svc -A
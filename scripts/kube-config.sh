#!/bin/bash
CLUSTER_NAME="eks-demo-cluster"
API_SERVER="https://405F20DCFA0844FEE9F180D17ADD3B21.gr7.us-east-1.eks.amazonaws.com"
CA_FILE="$HOME/.kube/${CLUSTER_NAME}-ca.crt"
TOKEN=$(pass k8s/${CLUSTER_NAME}/token)

kubectl config set-cluster "$CLUSTER_NAME" \
  --server="$API_SERVER" \
  --certificate-authority="$CA_FILE" \
  --embed-certs=true

kubectl config set-credentials pass-user \
  --token="$TOKEN"

kubectl config set-context pass-context \
  --cluster="$CLUSTER_NAME" \
  --user=pass-user

kubectl config use-context pass-context


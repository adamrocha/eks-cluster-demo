#!/usr/bin/env bash
# This script updates the kubeconfig for an EKS cluster.


CLUSTER_NAME="eks-demo-cluster"
REGION="us-east-1"

aws eks update-kubeconfig \
    --region "$REGION" \
    --name "$CLUSTER_NAME"

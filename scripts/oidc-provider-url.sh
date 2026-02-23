#!/usr/bin/env bash

export AWS_PAGER=""

set -euo pipefail

CLUSTER_NAME="eks-cluster-demo"
REGION="us-east-1"

aws eks describe-cluster \
	--name "${CLUSTER_NAME}" \
	--region "${REGION}" \
	--query "cluster.identity.oidc.issuer" \
	--output text

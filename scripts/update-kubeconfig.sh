#!/usr/bin/env bash
set -euo pipefail

# 1. Configuration
readonly CLUSTER_NAME="${CLUSTER_NAME:-eks-cluster-demo}"
readonly REGION="${REGION:-us-east-1}"
export AWS_PAGER=""

# 2. Pre-flight check: Is AWS CLI installed?
if ! command -v aws &>/dev/null; then
	echo "❌ Error: 'aws' command not found. Please install the AWS CLI."
	exit 1
fi

# 3. Execution
echo "🔄 Updating kubeconfig for ${CLUSTER_NAME} in ${REGION}..."

if aws eks update-kubeconfig --region "${REGION}" --name "${CLUSTER_NAME}"; then
	echo "✅ Kubeconfig updated successfully."
else
	echo "❌ Failed to update kubeconfig."
	exit 1
fi

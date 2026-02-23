#!/usr/bin/env bash
# Check if tfstate s3 bucket exists, if not create it
set -euo pipefail

export AWS_PAGER=""

TF_STATE_BUCKET="terraform-state-bucket-2727"
REGION="us-east-1"

if ! aws s3api head-bucket --bucket "${TF_STATE_BUCKET}" --region "${REGION}" >/dev/null 2>&1; then
	echo "Creating S3 bucket: ${TF_STATE_BUCKET}"
	aws s3api create-bucket --bucket "${TF_STATE_BUCKET}"
	if [[ ${REGION} == "us-east-1" ]]; then
		aws s3api create-bucket \
			--bucket "${TF_STATE_BUCKET}" \
			--region "${REGION}" \
			--create-bucket-configuration LocationConstraint="${REGION}" \
			>/dev/null
	else
		aws s3api create-bucket \
			--bucket "${TF_STATE_BUCKET}" \
			--region "${REGION}" \
			--create-bucket-configuration LocationConstraint="${REGION}" \
			>/dev/null
	fi
fi

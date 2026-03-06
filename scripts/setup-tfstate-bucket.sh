#!/usr/bin/env bash
# Create Terraform state S3 bucket if needed and configure baseline protections.
# Optional: set ENFORCE_SETTINGS=1 to apply settings even when bucket already exists.
set -euo pipefail

export AWS_PAGER=""

S3_BUCKET="${S3_BUCKET:-${TF_STATE_BUCKET:-terraform-state-bucket-2727}}"
AWS_REGION="${AWS_REGION:-${REGION:-us-east-1}}"
ENFORCE_SETTINGS="${ENFORCE_SETTINGS:-0}"

echo "Checking S3 bucket: ${S3_BUCKET}"

if aws s3api head-bucket --bucket "${S3_BUCKET}" --region "${AWS_REGION}" >/dev/null 2>&1; then
	echo "Bucket '${S3_BUCKET}' already exists."
	if [[ ${ENFORCE_SETTINGS} != "1" ]]; then
		echo "Skipping settings reconciliation (set ENFORCE_SETTINGS=1 to enforce)."
		exit 0
	fi
	echo "ENFORCE_SETTINGS=1 set, reconciling bucket settings..."
else
	echo "Creating bucket '${S3_BUCKET}' in region '${AWS_REGION}'..."
	if [[ ${AWS_REGION} == "us-east-1" ]]; then
		aws s3api create-bucket \
			--bucket "${S3_BUCKET}" \
			--region "${AWS_REGION}" >/dev/null
	else
		aws s3api create-bucket \
			--bucket "${S3_BUCKET}" \
			--region "${AWS_REGION}" \
			--create-bucket-configuration LocationConstraint="${AWS_REGION}" >/dev/null
	fi
fi

echo "Enabling versioning on '${S3_BUCKET}'..."
aws s3api put-bucket-versioning \
	--bucket "${S3_BUCKET}" \
	--versioning-configuration Status=Enabled \
	--region "${AWS_REGION}" >/dev/null

echo "Enabling server-side encryption (AES256) on '${S3_BUCKET}'..."
aws s3api put-bucket-encryption \
	--bucket "${S3_BUCKET}" \
	--server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' \
	--region "${AWS_REGION}" >/dev/null

echo "Bucket '${S3_BUCKET}' configured (versioning + encryption)."

#!/usr/bin/env bash
set -euo pipefail

export AWS_PAGER=""

S3_BUCKET="${S3_BUCKET:-terraform-state-bucket-2727}"
AWS_REGION="${AWS_REGION:-us-east-1}"
FORCE="${FORCE:-0}"
DRY_RUN="${DRY_RUN:-0}"

if [[ "${FORCE}" == "1" ]]; then
	confirm="y"
else
	echo "⚠️  WARNING: This will delete the S3 bucket: ${S3_BUCKET}"
	read -r -p "Are you sure? (y/N): " confirm
fi

if [[ "${confirm}" != "y" ]]; then
	echo "❎ Aborted."
	exit 0
fi

echo "🔄 Scanning bucket for versioned objects..."
while true; do
	output=$(aws s3api list-object-versions --bucket "${S3_BUCKET}" --output json)
	delete_json=$(echo "${output}" | jq '[.Versions[]?, .DeleteMarkers[]?] | map({Key: .Key, VersionId: .VersionId})')
	count=$(echo "${delete_json}" | jq 'length')

	if [[ "${count}" -eq 0 ]]; then
		break
	fi

	echo "   found ${count} objects..."
	for start in $(seq 0 1000 "${count}"); do
		batch=$(echo "${delete_json}" | jq -c ".[$start:$start+1000]")
		batch_count=$(echo "${batch}" | jq 'length')

		if [[ "${batch_count}" -gt 0 ]]; then
			if [[ "${DRY_RUN}" == "1" ]]; then
				echo "   [DRY RUN] would delete ${batch_count} objects:"
				echo "${batch}" | jq -r '.[].Key + " (" + .VersionId + ")"'
			else
				echo "   deleting ${batch_count} objects..."
				echo "${batch}" | jq '{Objects: ., Quiet: false}' | \
					aws s3api delete-objects --bucket "${S3_BUCKET}" --delete file:///dev/stdin >/dev/null
			fi
		fi
	done

	[[ "${DRY_RUN}" == "1" ]] && break
done

if [[ "${DRY_RUN}" == "1" ]]; then
	echo "❎ DRY RUN complete. Bucket NOT deleted."
else
	echo "❌ Deleting bucket..."
	aws s3api delete-bucket --bucket "${S3_BUCKET}" --region "${AWS_REGION}"
	echo "✅ Bucket ${S3_BUCKET} deleted."
fi

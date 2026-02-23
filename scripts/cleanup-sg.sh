#!/bin/bash
export AWS_PAGER=""

set -euo pipefail

# Required settings
REGION="us-east-1"
VPC_NAME="eks-vpc"

echo "🔍 Locating VPC with tag Name=\"${VPC_NAME}\" in region \"${REGION}\"..."
VPC_ID=$(aws ec2 describe-vpcs \
	--region "${REGION}" \
	--filters "Name=tag:Name,Values=${VPC_NAME}" \
	--query "Vpcs[0].VpcId" \
	--output text)

if [[ ${VPC_ID} == "None" || -z ${VPC_ID} ]]; then
	echo "❌ VPC named '${VPC_NAME}' not found in region '${REGION}'. Exiting."
	exit 1
fi

echo "✅ Found VPC: ${VPC_ID}"
echo ""

# Get SG IDs, handling the tab-to-newline conversion cleanly
SG_IDS=$(aws ec2 describe-security-groups \
	--region "${REGION}" \
	--filters "Name=vpc-id,Values=${VPC_ID}" \
	--query "SecurityGroups[*].GroupId" \
	--output text | tr '\t' '\n')

# Loop through each SG
while IFS= read -r sg; do
	[[ -z ${sg} ]] && continue

	# Fetch GroupName and check if it's the 'default' group
	SG_DETAILS=$(aws ec2 describe-security-groups \
		--region "${REGION}" \
		--group-ids "${sg}" \
		--query "SecurityGroups[0].[GroupName, Tags[?Key=='kubernetes.io/cluster/']]" \
		--output json)

	GROUP_NAME=$(echo "${SG_DETAILS}" | jq -r '.[0]')

	if [[ ${GROUP_NAME} == "default" ]]; then
		echo "⚠️  Skipping protected default SG: ${sg}"
		continue
	fi

	echo -n "🔍 Checking ${sg} (${GROUP_NAME})... "

	# Check for ENIs attached to this SG
	ENIS=$(aws ec2 describe-network-interfaces \
		--region "${REGION}" \
		--filters "Name=group-id,Values=${sg}" \
		--query "NetworkInterfaces[*].NetworkInterfaceId" \
		--output text)

	if [[ -z ${ENIS} ]]; then
		echo -n "unused by ENIs → attempting deletion... "

		# Capture error output to avoid cluttering stdout
		if err_out=$(aws ec2 delete-security-group --region "${REGION}" --group-id "${sg}" 2>&1); then
			echo "✅ deleted"
		else
			if [[ ${err_out} == *"DependencyViolation"* ]]; then
				echo "⚠️  skipped (referenced by other SGs)"
			else
				echo "❌ error: ${err_out}"
			fi
		fi
	else
		echo "in use by ENIs → skipping"
	fi
done <<<"${SG_IDS}"

echo -e "\n✅ Cleanup completed."

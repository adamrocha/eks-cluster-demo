#!/usr/bin/env bash
# This script sends a simple command to an SSM-managed instance to verify connectivity and command execution.
set -euo pipefail

export AWS_PAGER=""

REGION="${AWS_REGION:-us-east-1}"
INSTANCE_ID="${1-}"

if [[ -z ${INSTANCE_ID} ]]; then
	INSTANCE_ID="$(aws ssm describe-instance-information \
		--region "${REGION}" \
		--query "InstanceInformationList[?PingStatus=='Online']|[0].InstanceId" \
		--output text)"
fi

if [[ -z ${INSTANCE_ID} || ${INSTANCE_ID} == "None" ]]; then
	echo "No online SSM-managed instance found in region ${REGION}."
	exit 1
fi

echo "Using instance: ${INSTANCE_ID} (region: ${REGION})"

COMMAND_ID="$(aws ssm send-command \
	--region "${REGION}" \
	--instance-ids "${INSTANCE_ID}" \
	--document-name "AWS-RunShellScript" \
	--parameters commands='["echo ansible-ssm-ping-ok","uname -a"]' \
	--query 'Command.CommandId' \
	--output text)"

echo "Command sent: ${COMMAND_ID}"

aws ssm wait command-executed \
	--region "${REGION}" \
	--command-id "${COMMAND_ID}" \
	--instance-id "${INSTANCE_ID}"

STATUS="$(aws ssm get-command-invocation \
	--region "${REGION}" \
	--command-id "${COMMAND_ID}" \
	--instance-id "${INSTANCE_ID}" \
	--query 'Status' \
	--output text)"

echo "Status: ${STATUS}"

aws ssm get-command-invocation \
	--region "${REGION}" \
	--command-id "${COMMAND_ID}" \
	--instance-id "${INSTANCE_ID}" \
	--query '{Stdout:StandardOutputContent, Stderr:StandardErrorContent}' \
	--output yaml

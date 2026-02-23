#!/usr/bin/env bash
# Stop all EC2 instances in the account

set -euo pipefail

export AWS_PAGER=""

INSTANCE_IDS=$(aws ec2 describe-instances \
	--query 'Reservations[*].Instances[*].InstanceId' \
	--output text)

if [[ -z ${INSTANCE_IDS} ]]; then
	echo "No EC2 instances found to stop."
	exit 0
fi

echo "Stopping EC2 instances: ${INSTANCE_IDS}"

aws ec2 stop-instances \
	--instance-ids "${INSTANCE_IDS}"

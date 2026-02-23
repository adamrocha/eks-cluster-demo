#!/usr/bin/env bash
# Start all EC2 instances in the account
set -euo pipefail

export AWS_PAGER=""

INSTANCE_IDS=$(aws ec2 describe-instances \
	--query 'Reservations[*].Instances[*].InstanceId' \
	--output text)

if [[ -z ${INSTANCE_IDS} ]]; then
	echo "No EC2 instances found to start."
	exit 0
fi

echo "Starting EC2 instances: ${INSTANCE_IDS}"

aws ec2 start-instances \
	--instance-ids "${INSTANCE_IDS}"

#!/usr/bin/env bash
# aws ssm start-session --target <instance-id>

set -euo pipefail

export AWS_PAGER=""

REGION="${AWS_REGION:-us-east-1}"

aws ssm describe-instance-information \
	--region "${REGION}" \
	--query "InstanceInformationList[*].{InstanceId:InstanceId, PingStatus:PingStatus, PlatformName:PlatformName, PlatformVersion:PlatformVersion, PrivateIP:IPAddress}" \
	--output table

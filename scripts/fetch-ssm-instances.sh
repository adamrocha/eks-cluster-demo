#!/usr/bin/env bash
# aws ssm start-session --target <instance-id>

set -euo pipefail

export AWS_PAGER=""

aws ssm describe-instance-information \
    --query "InstanceInformationList[*].[InstanceId, PingStatus, PlatformName, AgentVersion]" \
    --output table

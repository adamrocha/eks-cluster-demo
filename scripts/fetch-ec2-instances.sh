#!/usr/bin/env bash
# aws ssm start-session --target <instance-id>

set -euo pipefail

export AWS_PAGER=""

aws ec2 describe-instances \
  --query "Reservations[].Instances[].{ID:InstanceId, Platform:PlatformDetails, PrivateIP:PrivateIpAddress, PublicIP:PublicIpAddress, State:State.Name, AZ:Placement.AvailabilityZone, Type:InstanceType}" \
  --filters Name=instance-state-name,Values=running \
  --output table

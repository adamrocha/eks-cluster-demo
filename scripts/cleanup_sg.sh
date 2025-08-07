#!/bin/bash
export AWS_PAGER=""

set -euo pipefail

# Required settings
REGION="us-east-1"
VPC_NAME="eks-vpc"

echo "🔍 Locating VPC with tag Name=$VPC_NAME in region $REGION..."
VPC_ID=$(aws ec2 describe-vpcs \
  --region "$REGION" \
  --filters "Name=tag:Name,Values=$VPC_NAME" \
  --query "Vpcs[0].VpcId" \
  --output text)

if [[ "$VPC_ID" == "None" || -z "$VPC_ID" ]]; then
  echo "❌ VPC named '$VPC_NAME' not found in region '$REGION'. Exiting."
  exit 1
fi

echo "✅ Found VPC: $VPC_ID"

echo "🔍 Fetching all security groups in VPC $VPC_NAME..."

# Get security group IDs, one per line
SG_IDS=$(aws ec2 describe-security-groups \
  --region "$REGION" \
  --filters Name=vpc-id,Values="$VPC_ID" \
  --query "SecurityGroups[*].GroupId" \
  --output text | tr '\t' '\n')

echo "✅ Found $(echo "$SG_IDS" | wc -l) SGs"
echo ""

# Loop through each SG
while IFS= read -r sg; do
  [[ -z "$sg" ]] && continue

  # Skip default SG
  GROUP_NAME=$(aws ec2 describe-security-groups \
    --region "$REGION" \
    --group-ids "$sg" \
    --query 'SecurityGroups[0].GroupName' \
    --output text)

  if [[ "$GROUP_NAME" == "default" ]]; then
    echo "⚠️  Skipping default SG: $sg"
    continue
  fi

  echo -n "🔍 Checking $sg ($GROUP_NAME)... "

  ENIS=$(aws ec2 describe-network-interfaces \
    --region "$REGION" \
    --filters Name=group-id,Values="$sg" \
    --query "NetworkInterfaces[*].NetworkInterfaceId" \
    --output text)

  if [[ -z "$ENIS" ]]; then
    echo -n "unused → deleting... "
    if aws ec2 delete-security-group --region "$REGION" --group-id "$sg" 2>/tmp/sg-delete-error; then
      echo "✅ deleted"
    else
      ERROR_MSG=$(cat /tmp/sg-delete-error)
      if echo "$ERROR_MSG" | grep -q "DependencyViolation"; then
        echo "⚠️  dependency violation → skipped"
      else
        echo "❌ unexpected error:"
        echo "$ERROR_MSG"
      fi
    fi
  else
    echo "still in use → skipping"
  fi
done <<< "$SG_IDS"

echo ""
echo "✅ Cleanup completed."

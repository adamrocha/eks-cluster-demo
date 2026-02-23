#!/usr/bin/env bash
# This script fetches the total billing amount for the current month using AWS CLI.
set -euo pipefail

export AWS_PAGER=""

# 1. Handle Date Portability (Linux vs macOS)
if date --version >/dev/null 2>&1; then
	# GNU Date (Linux)
	START_DATE="$(date +%Y-%m-01)"
	END_DATE="$(date -d "tomorrow" +%Y-%m-%d)"
else
	# BSD Date (macOS)
	START_DATE="$(date +%Y-%m-01)"
	END_DATE="$(date -v+1d +%Y-%m-%d)"
fi

# 2. Dependency Check
if ! command -v aws &>/dev/null; then
	echo "Error: AWS CLI could not be found." >&2
	exit 1
fi

# 3. Authentication Check
if ! aws sts get-caller-identity &>/dev/null; then
	echo "Error: You are not authenticated. Please configure your AWS CLI." >&2
	exit 1
fi

echo "Fetching billing for period: ${START_DATE} to ${END_DATE}"

# 4. Fetch the total billing amount
if ! aws ce get-cost-and-usage \
	--time-period "Start=${START_DATE},End=${END_DATE}" \
	--granularity MONTHLY \
	--metrics "UnblendedCost" \
	--query "ResultsByTime[].{Start:TimePeriod.Start,Amount:Total.UnblendedCost.Amount,Unit:Total.UnblendedCost.Unit}" \
	--output table; then

	echo "Error: Failed to access Cost Explorer. Check IAM policy 'ce:GetCostAndUsage'." >&2
	exit 1
fi

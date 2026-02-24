#!/usr/bin/env python3
import datetime
import sys

import boto3

# Threshold for "Unexpected" costs (Adjust as needed)
THRESHOLD = 10.00

SERVICE_MAP = {
    "Amazon Elastic Container Service for Kubernetes": "EKS",
    "Amazon Elastic Compute Cloud - Compute": "EC2 - Compute",
    "Amazon Elastic Load Balancing": "ELB",
    "Amazon Virtual Private Cloud": "VPC",
    "Amazon Simple Storage Service": "S3",
    "AWS Key Management Service": "KMS",
    "AmazonCloudWatch": "CloudWatch",
}

# Terminal Colors
BLUE = "\033[1;34m"
GREEN = "\033[1;32m"
RED = "\033[1;31m"
BOLD = "\033[1m"
RESET = "\033[0m"


def get_time_period():
    start = datetime.date.today().replace(day=1)
    end = datetime.date.today() + datetime.timedelta(days=1)
    return start.strftime("%Y-%m-%d"), end.strftime("%Y-%m-%d")


def main():
    try:
        ce = boto3.client("ce", region_name="us-east-1")
        start, end = get_time_period()

        response = ce.get_cost_and_usage(
            TimePeriod={"Start": start, "End": end},
            Granularity="MONTHLY",
            Metrics=["UnblendedCost"],
            GroupBy=[{"Type": "DIMENSION", "Key": "SERVICE"}],
        )
    except Exception as e:
        print(f"{RED}Error:{RESET} {e}")
        sys.exit(1)

    print(f"\n{BLUE}--- AWS Monthly Spend: {start} to {end} ---{RESET}")
    print(f"{'Service':<30} {'Amount':>12}")
    print("-" * 43)

    total_cost = 0.0
    groups = []
    for result in response.get("ResultsByTime", []):
        for group in result.get("Groups", []):
            name = group["Keys"][0]
            cost = float(group["Metrics"]["UnblendedCost"]["Amount"])
            if cost > 0.005:
                groups.append((name, cost))

    # Sort: Highest cost first
    groups.sort(key=lambda x: x[1], reverse=True)

    for name, cost in groups:
        display_name = SERVICE_MAP.get(name, name[:30])
        cost_str = f"${cost:.2f}"

        # Color coding: Red if >= THRESHOLD, else Green
        color = RED if cost >= THRESHOLD else GREEN
        print(f"{display_name:<30} {color}{cost_str:>12}{RESET}")
        total_cost += cost

    total_str = f"${total_cost:.2f}"
    print("-" * 43)
    print(f"{BOLD}{'TOTAL':<30} {total_str:>12}{RESET}\n")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
# Fetch AWS billing information

import boto3
import datetime
import sys
from botocore.exceptions import NoCredentialsError, ClientError

def get_time_period():
    start = datetime.date.today().replace(day=1)
    end = datetime.date.today() + datetime.timedelta(days=1)
    return start.strftime("%Y-%m-%d"), end.strftime("%Y-%m-%d")

def main():
    try:
        client = boto3.client("ce")
        sts = boto3.client("sts")
        # Check authentication
        sts.get_caller_identity()
    except NoCredentialsError:
        print("You are not authenticated. Please configure your AWS CLI.")
        sys.exit(1)
    except ClientError as e:
        print(f"Error: {e}")
        sys.exit(1)

    start, end = get_time_period()
    try:
        response = client.get_cost_and_usage(
            TimePeriod={"Start": start, "End": end},
            Granularity="MONTHLY",
            Metrics=["UnblendedCost"]
        )
    except ClientError as e:
        print("You do not have permission to access Cost Explorer. Please check your IAM policies.")
        sys.exit(1)

    results = response.get("ResultsByTime", [])
    print("{:<12} {:<15}".format("Start", "Amount (USD)"))
    for result in results:
        amount_str = result.get("Total", {}).get("UnblendedCost", {}).get("Amount", "0.00")
        try:
            # Convert to float and format to two decimal places
            amount = float(amount_str)
        except ValueError:
            amount = 0.00
        print("{:<12} ${:<14.2f}".format(result["TimePeriod"]["Start"], amount))

if __name__ == "__main__":
    main()
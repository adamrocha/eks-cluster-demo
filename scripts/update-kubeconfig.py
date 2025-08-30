#!/usr/bin/env python3
"""
update_kubeconfig.py
Updates kubeconfig for an AWS EKS cluster using boto3 and subprocess.
"""
import os
import sys
import subprocess
import boto3

AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
CLUSTER_NAME = os.getenv("CLUSTER_NAME", "eks-demo-cluster")


def update_kubeconfig(cluster_name, region):
    """
    Updates kubeconfig for the given EKS cluster using AWS CLI.
    """
    try:
        # Check if cluster exists
        eks = boto3.client("eks", region_name=region)
        eks.describe_cluster(name=cluster_name)
    except Exception as e:
        print(f"❌ EKS cluster '{cluster_name}' not found in region '{region}'.")
        sys.exit(1)

    # Run AWS CLI command to update kubeconfig
    cmd = [
        "aws", "eks", "update-kubeconfig",
        "--name", cluster_name,
        "--region", region
    ]
    try:
        subprocess.run(cmd, check=True)
        print(f"✅ kubeconfig updated for cluster '{cluster_name}' in region '{region}'.")
    except subprocess.CalledProcessError:
        print("❌ Failed to update kubeconfig.")
        sys.exit(1)


def main():
    update_kubeconfig(CLUSTER_NAME, AWS_REGION)

if __name__ == "__main__":
    main()

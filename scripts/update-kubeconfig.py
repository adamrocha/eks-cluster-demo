#!/usr/bin/env python3
"""
This script updates the kubeconfig file for an EKS cluster using pure Python (Boto3 and PyYAML).
It fetches cluster details from AWS and merges them into the existing kubeconfig without using subprocess calls. This approach is more efficient and avoids potential issues with external command execution. Make sure to have AWS credentials configured and the necessary permissions to access EKS clusters.
"""

import sys
from pathlib import Path

import boto3
import yaml
from botocore.exceptions import ClientError, NoCredentialsError

# --- Configuration ---
# Replace these strings with your actual cluster details for testing
CLUSTER_NAME = "eks-cluster-demo"
AWS_REGION = "us-east-1"


def update_kubeconfig_pure_python(cluster_name, region):
    """
    Updates kubeconfig using Boto3 and PyYAML (No Subprocess).
    """
    print(f"🔍 Fetching details for cluster: {cluster_name}...", flush=True)

    eks = boto3.client("eks", region_name=region)

    try:
        # 1. Fetch Cluster Metadata from AWS
        response = eks.describe_cluster(name=cluster_name)
        cluster_data = response["cluster"]
        cluster_arn = cluster_data["arn"]
        endpoint = cluster_data["endpoint"]
        ca_data = cluster_data["certificateAuthority"]["data"]

        # 2. Setup Kubeconfig path using Pathlib
        kube_dir = Path.home() / ".kube"
        kube_config_file = kube_dir / "config"
        kube_dir.mkdir(parents=True, exist_ok=True)

        # 3. Load or Initialize Config
        if kube_config_file.exists():
            with open(kube_config_file, "r") as f:
                config = yaml.safe_load(f) or {}
        else:
            config = {
                "apiVersion": "v1",
                "clusters": [],
                "contexts": [],
                "users": [],
                "kind": "Config",
            }

        # 4. Define EKS entries
        new_cluster = {
            "name": cluster_arn,
            "cluster": {"server": endpoint, "certificate-authority-data": ca_data},
        }

        new_user = {
            "name": cluster_arn,
            "user": {
                "exec": {
                    "apiVersion": "client.authentication.k8s.io/v1beta1",
                    "command": "aws",
                    "args": [
                        "eks",
                        "get-token",
                        "--cluster-name",
                        cluster_name,
                        "--region",
                        region,
                    ],
                    "interactiveMode": "IfAvailable",
                }
            },
        }

        new_context = {
            "name": cluster_arn,
            "context": {"cluster": cluster_arn, "user": cluster_arn},
        }

        # 5. Merge logic (Upsert)
        config["clusters"] = [
            c for c in config.get("clusters", []) if c["name"] != cluster_arn
        ] + [new_cluster]
        config["users"] = [
            u for u in config.get("users", []) if u["name"] != cluster_arn
        ] + [new_user]
        config["contexts"] = [
            ctx for ctx in config.get("contexts", []) if ctx["name"] != cluster_arn
        ] + [new_context]
        config["current-context"] = cluster_arn

        # 6. Write to file
        with open(kube_config_file, "w") as f:
            yaml.dump(config, f, default_flow_style=False)

        print(f"✅ Successfully updated: {kube_config_file}", flush=True)

    except NoCredentialsError:
        print("Error: AWS credentials not found. Run 'aws configure'.", flush=True)
    except ClientError as e:
        print(f"AWS API Error: {e.response['Error']['Message']}", flush=True)
    except Exception as e:
        print(f"Unexpected Error: {e}", flush=True)


def main():
    """
    Entry point for the script.
    """
    print(f"🐍 Python Interpreter: {sys.executable}", flush=True)
    update_kubeconfig_pure_python(CLUSTER_NAME, AWS_REGION)
    print("🏁 Execution Finished.", flush=True)


if __name__ == "__main__":
    main()

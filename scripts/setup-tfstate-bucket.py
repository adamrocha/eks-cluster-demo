#!/usr/bin/env python3
"""
setup_tfstate_bucket.py
Checks if the Terraform state S3 bucket exists, and creates it if not.
"""
import boto3
import sys
import os

def main():
    bucket_name = os.getenv("TF_STATE_BUCKET", "terraform-state-bucket-2727")
    region = os.getenv("REGION", "us-east-1")
    s3 = boto3.client("s3", region_name=region)

    # Check if bucket exists
    try:
        s3.head_bucket(Bucket=bucket_name)
        print(f"Bucket '{bucket_name}' already exists.")
    except Exception:
        print(f"Creating S3 bucket: {bucket_name}")
        create_args = {"Bucket": bucket_name}
        if region != "us-east-1":
            create_args["CreateBucketConfiguration"] = {"LocationConstraint": region}
        try:
            s3.create_bucket(**create_args)
            print(f"Bucket '{bucket_name}' created.")
        except Exception as e:
            print(f"Error creating bucket: {e}")
            sys.exit(1)

if __name__ == "__main__":
    main()
